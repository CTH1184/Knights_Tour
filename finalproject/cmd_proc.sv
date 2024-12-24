module cmd_proc(clk,rst_n,cmd,cmd_rdy,clr_cmd_rdy,send_resp,strt_cal,
                cal_done,heading,heading_rdy,lftIR,cntrIR,rghtIR,error,
				frwrd,moving,tour_go,fanfare_go);

  parameter FAST_SIM = 1;		// speeds up incrementing of frwrd register for faster simulation
  localparam signed err_nudge_right = (FAST_SIM) ? 12'h1FF : 12'h05F;
  localparam signed err_nudge_left = (FAST_SIM) ? 12'hE00 : 12'hFA1;

  ////////////////////////////
  // Internal Logic Signals //
  ////////////////////////////
  input clk,rst_n;					// 50MHz clock and asynch active low reset
  input [15:0] cmd;					// command from BLE
  input cmd_rdy;					// command ready
  output logic clr_cmd_rdy;			// mark command as consumed
  output logic send_resp;			// command finished, send_response via UART_wrapper/BT
  output logic strt_cal;			// initiate calibration of gyro
  input cal_done;					// calibration of gyro done
  input signed [11:0] heading;		// heading from gyro
  input heading_rdy;				// pulses high 1 clk for valid heading reading
  input lftIR;						// nudge error +
  input cntrIR;						// center IR reading (have I passed a line)
  input rghtIR;						// nudge error -
  output reg signed [11:0] error;	// error to PID (heading - desired_heading)
  output reg [9:0] frwrd;			// forward speed register
  output logic moving;				// asserted when moving (allows yaw integration)
  output logic tour_go;				// pulse to initiate TourCmd block
  output logic fanfare_go;			// kick off the "Charge!" fanfare on piezo


  typedef enum logic [2:0] {
    IDLE,
    CALIBRATE,
    WAIT_ERR,
    RAMP_UP_MAX,
    RAMP_DOWN
    } state_t;
  state_t current_state;
  state_t next_state;

  // SM control signals
  logic clr_frwrd;
  logic dec_frwrd;
  logic inc_frwrd;
  logic move_cmd;

  // internal frwrds speed register
  logic en_frwrd;
  logic max_spd;
  logic frwrd_zero;
  logic [7:0] inc_frwrd_amt;


  // internal square counter
  logic cntrIR_rise;
  logic cntrIR_q;
  logic [15:0] square_count;
  logic move_done;


  // internal PID interface
  logic [11:0] desired_heading;
  logic signed [11:0] err_nudge;
  logic error_meets_threshold;
  logic reset_err_meets_threshold;
  logic error_meets_threshold_sm;

  /////////////////////////////
  // Forwards Speed Register //
  /////////////////////////////

  assign frwrd_zero = (frwrd == 10'h0);
  assign max_spd = &frwrd[9:8];

  // only enable the register when there is a new heading ready, we are incrementing or decrementing forwards, and the register is not zero.
  assign en_frwrd =   (heading_rdy) ?
                      (((inc_frwrd & ~max_spd) | (dec_frwrd & ~frwrd_zero)) ? 1 : 0)
                      : 0;

  // if we are decrementing forwards, the decrement amount is doubled
  generate
    if (FAST_SIM)
      assign inc_frwrd_amt = 8'h20;
    else
      assign inc_frwrd_amt = 8'h03;
  endgenerate

  always_ff @(posedge clk, negedge rst_n)
    begin
      if (!rst_n)
        frwrd <= '0;
      else if (clr_frwrd)
        frwrd <= '0;
      else if (en_frwrd)
        frwrd <= (inc_frwrd) ? frwrd + inc_frwrd_amt : frwrd - (inc_frwrd_amt*2);
    end

////////////////////
// Square Counter //
////////////////////

// flop cntR for rising edge detect
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    cntrIR_q <= 0;
  else
    cntrIR_q <= cntrIR;
end
assign cntrIR_rise = cntrIR & ~cntrIR_q;

// counter
always_ff @(posedge clk)
begin
  if (move_cmd)
    square_count <= '0;
  else if (cntrIR_rise)
    square_count <= square_count + 1;
end

logic [3:0] cmd_q;

// cmd flop
always_ff @(posedge clk) begin
  if (move_cmd)
    cmd_q <= {cmd[2:0],1'b0};
end

// move_done logict command we receive. //
assign move_done = (square_count == cmd_q);

////////////////////
// PID Interface  //
////////////////////

// desired_heading flop
always_ff @(posedge clk, negedge rst_n) begin : desired_heading_ff
  if (!rst_n)
    desired_heading <= 12'h000;
  else if (move_cmd)
    desired_heading <= ((~|cmd[11:4]) ? 12'h000 : {cmd[11:4], 4'hF});
end

// err_nudge logic
always_comb begin
  casex ({lftIR, rghtIR})
    3'b1x:
      err_nudge = err_nudge_right;
    3'b01:
      err_nudge = err_nudge_left;
    3'b00:
      err_nudge = 0;
  endcase
end

assign error = heading - $signed(desired_heading) + err_nudge;
assign error_meets_threshold = ((error < 12'sh02C) && (error > 12'shFD4));

///////////////////
// State Machine //
///////////////////

// Handle state driver
always_ff @(posedge clk, negedge rst_n) begin
  if (!rst_n)
    current_state <= IDLE;
  else
    current_state <= next_state;
end

logic set_fanfare;
logic reset_fanfare;
logic move_with_fanfare;

always_ff @(posedge clk)
  if (set_fanfare)
    move_with_fanfare <= 1'b1;
  else if (reset_fanfare)
    move_with_fanfare <= 1'b0;


always_comb begin
  moving = 0;
  tour_go = 0;
  move_cmd = 0;
  inc_frwrd = 0;
  dec_frwrd = 0;
  clr_frwrd = 0;
  strt_cal = 0;
  clr_cmd_rdy = 0;
  set_fanfare = 0;
  reset_fanfare = 0;
  fanfare_go = 0;
  send_resp = 0;
  next_state = current_state;

  case (current_state)
    IDLE: begin
      if (cmd_rdy) begin

        ////////////////////////////////////////////////////////
        // change state depending on what command we receive. //
        ////////////////////////////////////////////////////////
        case(cmd[15:12])

          // calibrate the knight.
          4'b0010: begin
            strt_cal = 1;
            next_state = CALIBRATE;
          end

          // move without and with fanfare respectively.
          4'b0100,
          4'b0101: begin

            // determine if we play the fanfare at the end of the move.
            if (cmd[12]) begin
              set_fanfare = 1;
            end else begin
              reset_fanfare = 1;
            end

            // enable some flops that intake the command.
            move_cmd = 1;

            next_state = WAIT_ERR;
          end

          // command to start tour
          4'b0110: begin
            tour_go = 1;
          end

          // we receive an invalid command. do nothing.
          default: begin end
        endcase

        // consume the command.sv
        clr_cmd_rdy = 1;

      end
    end

    CALIBRATE: begin
      // acknowledge calibration finished.
      if (cal_done) begin
        send_resp = 1;
        next_state = IDLE;
      end
    end


    WAIT_ERR: begin
      moving = 1;
      if (error_meets_threshold) next_state = RAMP_UP_MAX;
    end


    RAMP_UP_MAX: begin
      moving = 1;
      inc_frwrd = 1;

      if (move_done)
        next_state = RAMP_DOWN;
    end


    RAMP_DOWN: begin
      moving = 1;
      dec_frwrd = 1;
      if (frwrd_zero) begin

        if (move_with_fanfare) fanfare_go = 1;

        send_resp = 1;
        next_state = IDLE;
      end
    end

    // MOVE: begin
    //   moving = 1;


    //  // handle ramping of forwards register.     
    //  if (move_done & ~frwrd_zero) begin
	  //     dec_frwrd = 1;
    //     inc_frwrd = 0;
    //  end else if (move_done & frwrd_zero) begin
    //     dec_frwrd = 0;
    //     inc_frwrd = 0;
    //  end else if (error_meets_threshold_sm) begin
	  //     inc_frwrd = 1;
    //     dec_frwrd = 0;
    //  end


    //  if (move_done & frwrd_zero) begin
     	
    //   if (move_with_fanfare) fanfare_go = 1;
	      
        
    //     send_resp = 1;
    //     reset_err_meets_threshold = 1;
	  //     next_state = IDLE;
    //  end
    // end

  endcase
end

endmodule