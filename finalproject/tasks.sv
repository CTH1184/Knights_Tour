`timescale 1ns/1ps
package knights_tour_tasks;

  // TODO pick a ""scientific"" value here.
  localparam signed HEADING_ERR_THRESHOLD = 40096;

  // This error threshold is +-h200.
  localparam signed POSITION_ERR_THRESHOLD = 16'sh200;

  localparam REPEAT_COUNT_TIMEOUT = 10000000;

  // The period of the clock in nanoseconds.
  localparam CLOCK_PERIOD = 10;

  ///////////////////////////////////////////////////////////////
  // Enumeration that specifies all of the different commands. //
  ///////////////////////////////////////////////////////////////


  /* Opcodes of commands we can send to cmd_proc */
  typedef enum logic [15:0] {
    CMD_OP_START_TOUR    = 16'h6000,
    CMD_OP_START_CAL     = 16'h2000,
    CMD_OP_MOVE          = 16'h4000,
    CMD_OP_MOVE_FANFARE  = 16'h5000
  } knights_tour_cmd_opcode_t;

  /* Directions of move commands we can send to cmd_proc */
  typedef enum logic [7:0] {
    DIR_NORTH   = 8'h00,
    DIR_EAST    = 8'hBF,
    DIR_SOUTH   = 8'h7F,
    DIR_WEST    = 8'h3F
  } knights_tour_dir_t;


  /**
    * Composes a move command with a specified direction, number of squares, and whether
    * the fanfare will be played during the move.
    *
    * @param dir           a direction specified by knights_tour_dir_t.
    * @param num_squares   the number of squares to move.
    * @param with_fanfare  whether to move with fanfare.
    *
  **/
  function automatic int composeMoveCmd(knights_tour_dir_t dir, reg [3:0] num_squares, reg with_fanfare);
    begin

    knights_tour_cmd_opcode_t cmd_move_header;
    int cmd;

    if (with_fanfare == 1) begin
      cmd_move_header = CMD_OP_MOVE_FANFARE;
    end else begin
      cmd_move_header = CMD_OP_MOVE;
    end

    cmd = cmd_move_header | (dir << 4) | num_squares;

    composeMoveCmd = cmd;
    end
  endfunction


  ///////////////////////
  // Instantiate tasks //
  ///////////////////////


  /**
    * Sets needed signals to zero, and deasserts reset.
    *
    * Specifically, sets clk, rst_n, cmd, and snd_cmd to 0. rst_n is then deasserted after
    * one clock cycle. One clock cycle of delay is factored in after reset is deasserted
    * to prevent any glitches.
    *
  **/
  task automatic init_signals(ref logic clk, ref logic RST_n, ref logic [15:0] cmd, ref logic send_cmd);
      begin
          clk = 0;
          RST_n = 0;
          cmd = 0;
          send_cmd = 0;
          @(posedge clk);
          @(negedge clk);
	  RST_n = 1;
      end
  endtask


  /**
   * Asserts that cal_done from inert_intf is 1'b1 within a reasonable time period.
   *
  **/
  task automatic assert_cal_done(ref logic cal_done, ref logic clk);
      begin
          fork
              begin
                  wait(cal_done);
                  $display("PASSED - cal_done asserted...");
                  disable timeout;
              end

              begin : timeout
                  repeat(100000000) @(posedge clk);
                  $display("FAILED - cal_done was not asserted in time!");
                  $stop();
              end
          join
      end
  endtask


  /**
   * Asserts that iNEMO_setup from SPI_iNEMO is 1'b1 within a reasonable time period.
   *
   * @param __setup__ the port that references iNEMO_setup.
  **/
  task automatic assert_iNEMO_setup(ref __setup__, ref clk);
    begin
      fork: wait_for_nemo_setup
      begin: timeout
        repeat(100000) @(posedge clk);
        $display("FAILED - Timeout on waiting for NEMO_setup");
        disable success;
        $stop();
      end
      begin: success
        wait(__setup__);
        $display("PASSED - NEMO_setup asserted.");
        disable timeout;
      end
    join
    end
  endtask


  /**
   * Asserts that the RemoteComm module that we are using to send commands receives a valid
   * response.
   *
   * This task checks that resp_rdy is asserted within a reasonable time period. Then, it
   * checks that the expected resp is equal to the actual resp.
   *
  **/
  task automatic assert_resp(input logic [7:0] expected_resp,ref logic [7:0] actual_resp, ref clk, ref cmd_proc_send_resp, ref logic __resp_rdy__);
    begin


        fork

          begin : timeout_resp_rdy
            repeat(50000000) @(negedge clk);
            $display("FAILED: resp_rdy was not asserted in time!");
            $display("WARNING: Skipping resp check as resp_rdy was not asserted...");
            $stop();
          end
		
          begin
	    wait(cmd_proc_send_resp);
  	    $display("PASSED: cmd_proc send_resp asserted. Waiting for resp_rdy...");
            wait(__resp_rdy__);
	    $display("PASSED: resp_rdy asserted.");
		disable timeout_resp_rdy;
              if (actual_resp !== expected_resp) begin
                $display("FAILED: resp was not expected value!\nExpected: %2h, Actual: %2h",expected_resp,actual_resp);
              end else begin
                $display("PASSED: resp %2h returned.", actual_resp);
              end
          end

        join
    end
  endtask

  /**
   * Sends a command of any type.
   *
   * Additionally, checks if cmd_sent was asserted by cmd_proc.
   * @param input_cmd the command to send.
   *
  **/
  task automatic send_command(input logic [15:0] input_cmd, ref clk, ref logic [15:0] cmd, ref send_cmd, ref cmd_sent);
    begin

      $display("INFO - Sending cmd: 16'h%4h", input_cmd);

      // set the command
      cmd = input_cmd;

      // send the command
      @(negedge clk) send_cmd = 1;
      @(negedge clk) send_cmd = 0;

      // wait for cmd_sent
      fork
        begin : timeout_cmd_sent
          repeat (1000000) @(posedge clk);
          $display("FAILED - cmd_sent timeout!");
          $stop();
        end

        begin
          wait(cmd_sent);
          disable timeout_cmd_sent;
          $display("INFO - cmd_sent was asserted...");
        end
      join

    end
  endtask

  /**
   * Asserts that the heading of the robot is correct before the forward register is ramped.
   *
   * In detail, this task checks that error_meets_threshold is asserted from cmd_proc. Then,
   * it checks if the robot heading is within a certain error threshold.
   *
   * @param error_meets_threshold reference to the port of cmd_proc.error_meets_threshold.
   * @param expected_heading      the expected heading of the robot.
   * @param robot_heading         the actual heading of the robot.
   *
  **/
  task automatic assert_move_command_turn_valid(input reg signed [19:0] expected_heading, ref reg signed [19:0] heading_robot, ref clk, ref error_meets_threshold);
    begin

      int signed sign = 1;

      reg signed [20:0] expected_heading_signed, heading_robot_signed;

      // sign extend each of these signals in order to correctly compare them.
      heading_robot_signed = {heading_robot[19], heading_robot};
      expected_heading_signed = {expected_heading[19], expected_heading};


      $display("INFO - Waiting for robot to complete heading change...");

      fork

        begin : timeout
          repeat(10000000) @(negedge clk);
          $display("FAILED - Timeout on waiting for heading to meet error threshold");
          $stop();
        end

        begin
          wait(error_meets_threshold);
          $display("INFO - error_meets_threshold asserted. Checking for a valid heading...");
          disable timeout;

          // this is so the signed comparison works. effectively an absolute value function.
          if ((heading_robot - expected_heading) < 0) begin
            sign = -1;
          end

          if (((heading_robot - expected_heading)*sign) > HEADING_ERR_THRESHOLD) begin
            $display("FAILED - Heading was not the expected value. Expected: %0d, Actual: %0d", expected_heading, heading_robot);
            $stop();
          end else begin
            $display("PASSED - Heading was the expected value. Expected: %0d, Actual: %0d", expected_heading, heading_robot);
          end

        end

      join
    end
  endtask

  /**
   * Asserts that the cntr_IR signal goes high twice, indicating that the robot has crossed one piece of reflective tape, and moved one square.
   *
   * @param cntrIR_n Reference to the cntrIR_n signal.
   * @param clk      Reference to the clock signal.
  **/
  task automatic assert_cntr_ir_crossed(ref logic cntrIR_n, ref clk);
    begin

      fork begin

        fork
          begin : timeout
            repeat(50000000) @(negedge clk);
            $display("FAILED - cntr_IR was not high twice!.");
            $stop();
          end

          begin
            wait(~cntrIR_n);
            $display("INFO - cntr_IR fired once...");
            wait(cntrIR_n);
            wait(~cntrIR_n);
            $display("PASSED - cntr_IR fired twice. We have crossed the reflective tape.");
            disable timeout;
          end
        join

      end join


    end
  endtask




  /**
   * Asserts that the position given in expected_x and expected_y is within a certain error threshold of the current position.
   *
   * @param curr_x      reference to the current x position of the robot.
   * @param curr_y      reference to the current y position of the robot.
   * @param expected_x  the expected x position of the robot.
   * @param expected_y  the expected y position of the robot.
  **/
  task automatic assert_position_valid(ref reg [14:0] curr_x, ref reg [14:0] curr_y, input reg [14:0] expected_x, input reg [14:0] expected_y);
    begin

      reg signed [15:0] curr_x_signed, curr_y_signed;
      reg signed [15:0] expected_x_signed, expected_y_signed;

      int signed sign_x = 1;
      int signed sign_y = 1;

      // TODO we might have to do this for assert_heading_valid as well. Look into this.
      // sign extend each of these signals in order to correctly compare them.
      curr_x_signed = {curr_x[14], curr_x};
      curr_y_signed = {curr_y[14], curr_y};
      expected_x_signed = {expected_x[14], expected_x};
      expected_y_signed = {expected_y[14], expected_y};

      // this is so the signed comparison works. effectively an absolute value function.
      if ((curr_x_signed - expected_x_signed) < 0) begin
        sign_x = -1;
      end

      if ((curr_y_signed - expected_y) < 0) begin
        sign_y = -1;
      end

      // check if either position value is out of bounds.
      if ((((curr_x_signed - expected_x_signed)*sign_x) > POSITION_ERR_THRESHOLD) || (((curr_y_signed - expected_y_signed)*sign_y) > POSITION_ERR_THRESHOLD)) begin
        $display("FAILED - Position was not the expected value. Expected: (%0h, %0h), Actual: (%0h, %0h)", expected_x, expected_y, curr_x, curr_y);
        $stop();
      end else begin
        $display("PASSED - Position was the expected value. Expected: (%0h, %0h), Actual: (%0h, %0h)", expected_x, expected_y, curr_x, curr_y);
      end

    end
  endtask

  /**
   * Prints the solution to the tour logic board.
   *
   * @param board the board to print the solution for.
  **/
  function automatic void print_tour_logic_solution(ref reg [4:0] board[0:4][0:4]);
	integer x,y;

	$display("INFO - Tour Logic Solution:");
	$display("---------------------------");
	for (y=4; y>=0; y--) begin
		$display("%2d %2d %2d %2d %2d\n",board[0][y],board[1][y],board[2][y],board[3][y],board[4][y]);
	end
	$display("---------------------------\n");
  endfunction

  /**
  * Task asserts that sponge tune is succesfully initiated.
  */
  task automatic assert_sponge_valid(ref clk, logic piezo, logic piezo_n);
    assert(piezo === 1'bx & piezo_n === 1'bx) else $display("Error: piezo signals toggling before go is asserted!");

    // Wait for the tune to complete 
    #50_000_000;

    // Verify that piezo and piezo_n are not toggling after the tune has completed
    #10;           // Give a little time for signals to settle
    assert(piezo === 1'bx && piezo_n === 1'bx) else $display("Error: piezo signals toggling after tune has completed!");

    $display("Fanfare completed successfully.");

  endtask

  /**
   * Prints out a section header for each section of tests.
   **/
  function void print_test_section_header(int section_num, string description);
    $display("##### SECTION %0x - %s #####", section_num, description);
  endfunction

  /**
   * Prints out a section footer for each section of tests.
  **/
  function void print_test_section_footer(int section_num);
    $display("##### END SECTION %0x #####\n",section_num);
  endfunction

endpackage
