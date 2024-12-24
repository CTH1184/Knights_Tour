module TourCmd(clk,rst_n,start_tour,move,mv_indx,
               cmd_UART,cmd,cmd_rdy_UART,cmd_rdy,
			   clr_cmd_rdy,send_resp,resp);

   input clk,rst_n;			   // 50MHz clock and asynch active low reset
   input start_tour;			   // from done signal from TourLogic
   input [7:0] move;			   // encoded 1-hot move to perform
   output reg [4:0] mv_indx;	// "address" to access next move
   input [15:0] cmd_UART;	   // cmd from UART_wrapper
   input cmd_rdy_UART;		   // cmd_rdy from UART_wrapper
   output [15:0] cmd;		      // multiplexed cmd to cmd_proc
   output logic cmd_rdy;			      // cmd_rdy signal to cmd_proc
   input clr_cmd_rdy;		      // from cmd_proc (goes to UART_wrapper too)
   input send_resp;			   // lets us know cmd_proc is done with the move command
   output [7:0] resp;		      // either 0xA5 (done) or 0x5A (in progress)
   logic incr_indx;

   // SM next state and output logic
   logic cmd_proc_sel;
   logic cmd_rdy_proc;

   logic [15:0] cmd_y, cmd_x, cmd_decomposed;

   // response is A5 if the cmd is from UART, or we have finished all moves.
   assign resp = (~cmd_proc_sel | (mv_indx == 5'd23)) ? 8'hA5 : 8'h5A;

   // Create states
   typedef enum logic [1:0] {
      IDLE,
      VERTICAL,
      HORIZONTAL
   } state_t;
   state_t state, nxt_state;

   // Next state driver
    always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)
         state <= IDLE;
      else
         state <= nxt_state;


   always_comb begin
      incr_indx = 0;
      cmd_decomposed = 0;
      cmd_rdy_proc = 0;
      cmd_proc_sel = 0;
      nxt_state = state;

      cmd_y = (move[0] || move[1]) ? 16'h4002     // up 2
               : (move[4] || move[5]) ? 16'h47F2  // down 2
               : (move[6] || move[3]) ? 16'h47F1  // down 1
               : (move[2] || move[7]) ? 16'h4001  // up 1
               : 16'hFFFF;

      cmd_x = (move[0] || move[5]) ? 16'h5BF1      // right 1
               : (move[1] || move[4]) ? 16'h53F1   // left 1
               : (move[6] || move[7]) ? 16'h5BF2   // right 2
               : (move[2] || move[3]) ? 16'h53F2   // left 2
               : 16'hFFFF; // error

      case (state)
         IDLE: begin
            if (start_tour) begin
               nxt_state = VERTICAL;
	            cmd_decomposed = cmd_y;
            end
         end
         VERTICAL: begin
	         cmd_proc_sel = 1;
            cmd_decomposed = cmd_y;
            if (send_resp) begin
		         nxt_state = HORIZONTAL;
	         end else begin
                cmd_rdy_proc = 1;
	         end
         end
         HORIZONTAL: begin
            cmd_proc_sel = 1;
            cmd_decomposed = cmd_x;
	         if (send_resp) begin
               if (mv_indx === 5'd23) begin
                  nxt_state = IDLE;
               end else begin
                  nxt_state = VERTICAL;
                  incr_indx = 1;
               end
            end else begin
               cmd_rdy_proc = 1;
            end
         end
         default:
            nxt_state = IDLE;
      endcase
   end

   always_ff @(posedge clk, negedge rst_n)
      if (!rst_n)
         mv_indx <= 0;
      else if (incr_indx)
         mv_indx <= mv_indx + 1;

   // Cmd output logic. If cmd_proc_sel, the cmd should come from TourLogic memory
   assign cmd = (cmd_proc_sel) ? cmd_decomposed : cmd_UART;
   assign cmd_rdy = (cmd_proc_sel) ? cmd_rdy_proc : cmd_rdy_UART;

endmodule
