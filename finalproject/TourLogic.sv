`default_nettype none
module TourLogic
#(
    parameter BOARD_SIZE = 5,
    parameter WRITE_MOVE_NUMBER = 0
)
(clk,rst_n,x_start,y_start,go,done,indx,move);

  //////////////////////////////////////////////////////////////////////////////////////////////
  // local parameters to determine the bitwidth of various signals based on passed parameters //
  //////////////////////////////////////////////////////////////////////////////////////////////
  localparam int MAX_NUM_MOVES = BOARD_SIZE**2 - 1;
  localparam int MOVE_REG_WIDTH = $clog2(MAX_NUM_MOVES);
  localparam int BOARD_MOVE_NUMBER_BITWIDTH = (WRITE_MOVE_NUMBER) ? MOVE_REG_WIDTH : 1;
  localparam int POSITION_BITWIDTH = $clog2(BOARD_SIZE);


  input logic clk,rst_n;				// 50MHz clock and active low asynch reset
  input logic [POSITION_BITWIDTH-1:0] x_start, y_start;	// starting position on 5x5 board
  input logic go;						// initiate calculation of solution
  input logic [MOVE_REG_WIDTH-1:0] indx;				// used to specify index of move to read out
  output logic done;			// pulses high for 1 clock when solution complete
  output logic [7:0] move;			// the move addressed by indx (1 of 24 moves)

  ////////////////////////////////////////
  // Declare needed internal registers //
  //////////////////////////////////////

  reg [BOARD_MOVE_NUMBER_BITWIDTH-1:0] board[0:BOARD_SIZE-1][0:BOARD_SIZE-1];     // keeps track if position visited
  reg [7:0] last_move[0:MAX_NUM_MOVES-1];		                            // last move tried from this spot
  reg [7:0] poss_moves[0:MAX_NUM_MOVES-1];		                            // stores possible moves from this
                                                                            // position as 8-bit one hot

  reg [7:0] move_try;				                                            // one hot encoding of move we will try next
  reg [MOVE_REG_WIDTH-1:0] move_num;				                // keeps track of move we are on
  reg [POSITION_BITWIDTH-1:0] xx,yy;					                        // current x & y position
  reg [POSITION_BITWIDTH-1:0] next_xx,next_yy;                                 // stores the next x & y position.
  reg [7:0] next_poss_moves;                                                    // stores the next possible moves.
  reg zero;                                                                     // asserted to clear the chess board array prior to calculating a solution.

  reg found_next_move;                                                          // asserted when we have found the next move_try.

  /////////////////////////////////////////
  // calculate the next x and y position //
  /////////////////////////////////////////
  always_comb begin
    next_xx = xx + off_x(move_try);
    next_yy = yy + off_y(move_try);
    next_poss_moves = calc_poss(next_xx, next_yy);
  end

  assign found_next_move = ((move_try & poss_moves[move_num]) != 0) ? ((board[next_xx][next_yy] == 0) ? 1 : 0) : 0;

    /////////////////////////
    // STATE LOGIC SIGNALS //
    /////////////////////////

    typedef enum logic [1:0] {
        IDLE,
        INIT,
        CALCULATE
    } state_t;

    state_t current_state;
    state_t next_state;

    logic init;
    logic update_position;
    logic backup;

  /////////////////////////////////
  // get move at a certain index //
  /////////////////////////////////
  assign move = last_move[indx];

  ///////////////////////////////////////////////////
  // The board memory structure keeps track of where
  // the knight has already visited.  Initially this
  // should be a 5x5 array of 5-bit numbers to store
  // the move number (helpful for debug).  Later it
  // can be reduced to a single bit (visited or not)
  ////////////////////////////////////////////////


  generate
    if (WRITE_MOVE_NUMBER) begin
        always_ff @(posedge clk)
            if (zero) begin
                for (int i = 0; i < BOARD_SIZE; i ++) begin
                    for (int j = 0; j < BOARD_SIZE; j++) begin
                        board[i][j] <= 0;
                    end
                end
            end
            else if (init)
            board[x_start][y_start] <= 1;	// mark starting position
            else if (update_position)
            board[next_xx][next_yy] <= move_num + 2;	// mark as visited
            else if (backup)
            board[xx][yy] <= 5'h0;			// mark as unvisited
    end else begin
        always_ff @(posedge clk)
            if (zero) begin
                for (int i = 0; i < BOARD_SIZE; i ++) begin
                    for (int j = 0; j < BOARD_SIZE; j++) begin
                        board[i][j] <= 0;
                    end
                end
            end
            else if (init)
            board[x_start][y_start] <= 1;	// mark starting position
            else if (update_position)
            board[next_xx][next_yy] <= 1;	// mark as visited
            else if (backup)
            board[xx][yy] <= 1'b0;          // mark as unvisited
    end
  endgenerate




  //////////////////////
  // next move try ff //
  //////////////////////
  always_ff @(posedge clk)
    if (update_position | backup | init)
        move_try <= 8'h01;
    else
        move_try <= (move_try << 1);

  //////////////////////////////////
  // update the position x and y. //
  //////////////////////////////////
  always_ff @(posedge clk)
    if (init) begin
        // load starting positions.
        xx <= x_start;
        yy <= y_start;
    end else if (update_position) begin
        // update the current position based
        // on the offset of the move we will try.
        xx <= next_xx;
        yy <= next_yy;
    end else if (backup) begin
        xx <= xx - off_x(last_move[move_num - 1]);
        yy <= yy - off_y(last_move[move_num - 1]);
    end

    ////////////////////////////////////
    // determine the next move number //
    ////////////////////////////////////
    always_ff @(posedge clk)
        if (init)
            move_num <= 0;
        else if (update_position)
            move_num <= move_num + 1;
        else if (backup)
            move_num <= move_num - 1;

    ///////////////////////////////
    // last move memory array    //
    ///////////////////////////////
    always_ff @(posedge clk)
        if (update_position)
            last_move[move_num] <= move_try;


    /////////////////////////////////
    // possible moves memory array //
    /////////////////////////////////
    always_ff @(posedge clk)
        if (init)
            poss_moves[0] <= calc_poss(x_start, y_start);
        else if (update_position)
            // recalculate previous guesses as we are finding a "better" solution.
            poss_moves[move_num + 1] <= next_poss_moves;
        else if (backup)

            // remove the bad guess from the previous set of possible moves.
            poss_moves[move_num - 1] <=
                (poss_moves[move_num - 1] & ~last_move[move_num - 1]);

    ///////////////////
    // State Machine //
    ///////////////////

    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;

    always_comb begin : state_logic

        // default assignments
        zero = 0;
        init = 0;
        update_position = 0;
        backup = 0;
        done = 0;
        next_state = current_state;

        // state logic
        unique case (current_state)
            IDLE: begin
                if (go) begin
                    zero = 1;
                    next_state = INIT;
                end
            end


            INIT: begin
                init = 1;
                next_state = CALCULATE;
            end

            ///////////////////////////////////////
            // Calculate the next move.          //
            ///////////////////////////////////////
            CALCULATE: begin

                // if we are on the 25th move, then the solution is
                // complete.
                if (move_num == MAX_NUM_MOVES) begin

                    done = 1;
                    next_state = IDLE;
                end else begin

                    // otherwise, keep trying different moves as long
                    // as there are possible moves.
                    if (found_next_move) begin
                        update_position = 1;
                    end

                    if (~|move_try) begin
                        backup = 1;
                    end
                end
            end
        endcase
    end

    ///////////////////////////////////////////////////
	// Consider writing a function that returns a packed byte of
	// all the possible moves (at least in bound) moves given
	// coordinates of Knight.
	/////////////////////////////////////////////////////

  function [7:0] calc_poss(input [2:0] xpos,ypos);


    // intermediate signals that are casted as signed.
    logic signed [3:0] signed_xpos, signed_ypos;

    calc_poss = '1;
    signed_xpos = {1'b0, xpos};
    signed_ypos = {1'b0, ypos};

    /////////////////////////////////
    // check x position boundaries //
    /////////////////////////////////

    if ((signed_xpos - 2) < 0) begin

        calc_poss[3:2] = 0;

        if ((signed_xpos - 1) < 0) begin
            calc_poss[1] = 0;
            calc_poss[4] = 0;
        end
    end

    if ((signed_xpos + 2) > (BOARD_SIZE-1)) begin

        calc_poss[7:6] = 0;

        if ((signed_xpos + 1) > (BOARD_SIZE-1)) begin
            calc_poss[0] = 0;
            calc_poss[5] = 0;
        end
    end

    /////////////////////////////////
    // check y position boundaries //
    /////////////////////////////////
    if ((signed_ypos - 2) < 0) begin

        calc_poss[5:4] = 0;

        if ((signed_ypos - 1) < 0) begin
            calc_poss[3] = 0;
            calc_poss[6] = 0;
        end
    end

    if ((signed_ypos + 2) > (BOARD_SIZE-1)) begin

        calc_poss[1:0] = 0;

        if ((signed_ypos + 1) > (BOARD_SIZE-1)) begin
            calc_poss[2] = 0;
            calc_poss[7] = 0;
        end
    end
  endfunction

  function signed [POSITION_BITWIDTH-1:0] off_x(input [7:0] try);
    ///////////////////////////////////////////////////
	// Consider writing a function that returns a the x-offset
	// the Knight will move given the encoding of the move you
	// are going to try.  Can also be useful when backing up
	// by passing in last move you did try, and subtracting
	// the resulting offset from xx
	/////////////////////////////////////////////////////
    // TODO optimize
    casez (try)
        8'b1???????: off_x =  2;
        8'b01??????: off_x =  2;
        8'b001?????: off_x =  1;
        8'b0001????: off_x = -1;
        8'b00001???: off_x = -2;
        8'b000001??: off_x = -2;
        8'b0000001?: off_x = -1;
        8'b00000001: off_x =  1;

        // don't care if not one of these positions.
        8'b00000000: off_x = 'x;
    endcase
  endfunction

  function signed [POSITION_BITWIDTH-1:0] off_y(input [7:0] try);
    ///////////////////////////////////////////////////
	// Consider writing a function that returns a the y-offset
	// the Knight will move given the encoding of the move you
	// are going to try.  Can also be useful when backing up
	// by passing in last move you did try, and subtracting
	// the resulting offset from yy
	/////////////////////////////////////////////////////

    // TODO optimize
    casez (try)
        8'b1???????: off_y =    1;
        8'b01??????: off_y =   -1;
        8'b001?????: off_y =   -2;
        8'b0001????: off_y =   -2;
        8'b00001???: off_y =   -1;
        8'b000001??: off_y =    1;
        8'b0000001?: off_y =    2;
        8'b00000001: off_y =    2;

        // don't care if not one of these positions.
        8'b00000000: off_y =    'x;
    endcase
  endfunction

endmodule
`default_nettype wire