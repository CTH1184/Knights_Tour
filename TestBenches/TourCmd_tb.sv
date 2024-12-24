module TourCmd_tb();
	
	logic clk,rst_n, start_tour, cmd_rdy_UART, cmd_rdy, clr_cmd_rdy, send_resp;
	logic [7:0] move, resp;
	logic [4:0] mv_indx;
	logic [15:0] cmd, cmd_UART;
	
	TourCmd iDUT(.*);

	// Convert binary to one-hot encoding
	assign move = 1 << mv_indx;
	
	initial begin
		clk = 0;
		rst_n = 0;
		start_tour = 0;
		cmd_UART = 0;
		cmd_rdy_UART = 0;
		clr_cmd_rdy = 0;
		send_resp = 0;
		
		// Assert reset
		@(posedge clk);
		@(negedge clk);
		rst_n = 1;
		repeat(5) @(posedge clk);
		
		$display("####### MOVE 0 #######");
		@(posedge clk) start_tour = 1;
		@(posedge clk) start_tour = 0;

		// Check vertical move
		if (cmd !== 16'h2002) begin
			$display("FAILED TEST 1 - vertical cmd should be %x, but was %x", 16'h2002, cmd);
			$stop;
		end else
			$display("PASSED TEST 1 - vertical cmd correctly asserted");
		
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(5) @(posedge clk);
		
		// Check horizontal move
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		if (cmd !== 16'h2BF1) begin
			$display("FAILED TEST 2 - horizontal cmd should be 16'h2BF1, but was %x", cmd);
			$stop;
		end else
			$display("PASSED TEST 2 - horizontal cmd correctly asserted");


		/****************************************************
		MOVE 1
		****************************************************/
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(10) @(posedge clk);
		
		$display("####### MOVE 1 #######");
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		repeat(50) @(posedge clk);
		
		// Check vertical
		if (cmd !== 16'h2002) begin
			$display("FAILED TEST 1 - vertical cmd should be %x, but was %x", 16'h2002, cmd);
			$stop;
		end else
			$display("PASSED TEST 1 - vertical cmd correctly asserted");
		
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(5) @(posedge clk);
		
		// Check horizontal
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		if (cmd !== 16'h23F1) begin
			$display("FAILED TEST 2 - horizontal cmd should be 16'h23F1, but was %x", cmd);
			$stop;
		end else
			$display("PASSED TEST 2 - horizontal cmd correctly asserted");


		/****************************************************
		MOVE 2
		****************************************************/
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(10) @(posedge clk);
		
		$display("####### MOVE 2 #######");
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		repeat(50) @(posedge clk);
		
		// Check vertical
		if (cmd !== 16'h2001) begin
			$display("FAILED TEST 1 - vertical cmd should be %x, but was %x", 16'h2002, cmd);
			$stop;
		end else
			$display("PASSED TEST 1 - vertical cmd correctly asserted");
		
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(5) @(posedge clk);
		
		// Check horizontal
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		if (cmd !== 16'h23F2) begin
			$display("FAILED TEST 2 - horizontal cmd should be 16'h23F1, but was %x", cmd);
			$stop;
		end else
			$display("PASSED TEST 2 - horizontal cmd correctly asserted");


		/****************************************************
		MOVE 3
		****************************************************/
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(10) @(posedge clk);
		
		$display("####### MOVE 3 #######");
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		repeat(50) @(posedge clk);
		
		// Check vertical
		if (cmd !== 16'h27F1) begin
			$display("FAILED TEST 1 - vertical cmd should be %x, but was %x", 16'h2002, cmd);
			$stop;
		end else
			$display("PASSED TEST 1 - vertical cmd correctly asserted");
		
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(5) @(posedge clk);
		
		// Check horizontal
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		if (cmd !== 16'h23F2) begin
			$display("FAILED TEST 2 - horizontal cmd should be 16'h23F1, but was %x", cmd);
			$stop;
		end else
			$display("PASSED TEST 2 - horizontal cmd correctly asserted");

		
		/****************************************************
		MOVE 4
		****************************************************/
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(10) @(posedge clk);
		
		$display("####### MOVE 4 #######");
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		repeat(50) @(posedge clk);
		
		// Check vertical
		if (cmd !== 16'h27F2) begin
			$display("FAILED TEST 1 - vertical cmd should be %x, but was %x", 16'h2002, cmd);
			$stop;
		end else
			$display("PASSED TEST 1 - vertical cmd correctly asserted");
		
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(5) @(posedge clk);
		
		// Check horizontal
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		if (cmd !== 16'h23F1) begin
			$display("FAILED TEST 2 - horizontal cmd should be 16'h23F1, but was %x", cmd);
			$stop;
		end else
			$display("PASSED TEST 2 - horizontal cmd correctly asserted");

		
		/****************************************************
		MOVE 5
		****************************************************/
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(10) @(posedge clk);
		
		$display("####### MOVE 5 #######");
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		repeat(50) @(posedge clk);
		
		// Check vertical
		if (cmd !== 16'h27F2) begin
			$display("FAILED TEST 1 - vertical cmd should be %x, but was %x", 16'h2002, cmd);
			$stop;
		end else
			$display("PASSED TEST 1 - vertical cmd correctly asserted");
		
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(5) @(posedge clk);
		
		// Check horizontal
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		if (cmd !== 16'h2BF1) begin
			$display("FAILED TEST 2 - horizontal cmd should be 16'h23F1, but was %x", cmd);
			$stop;
		end else
			$display("PASSED TEST 2 - horizontal cmd correctly asserted");

		/****************************************************
		MOVE 6
		****************************************************/
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(10) @(posedge clk);
		
		$display("####### MOVE 6 #######");
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		repeat(50) @(posedge clk);
		
		// Check vertical
		if (cmd !== 16'h27F1) begin
			$display("FAILED TEST 1 - vertical cmd should be %x, but was %x", 16'h27F1, cmd);
			$stop;
		end else
			$display("PASSED TEST 1 - vertical cmd correctly asserted");
		
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(5) @(posedge clk);
		
		// Check horizontal
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		if (cmd !== 16'h2BF2) begin
			$display("FAILED TEST 2 - horizontal cmd should be 16'h23F1, but was %x", cmd);
			$stop;
		end else
			$display("PASSED TEST 2 - horizontal cmd correctly asserted");
		
		/****************************************************
		MOVE 7
		****************************************************/
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(10) @(posedge clk);
		
		$display("####### MOVE 7 #######");
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		repeat(50) @(posedge clk);
		
		// Check vertical
		if (cmd !== 16'h2001) begin
			$display("FAILED TEST 1 - vertical cmd should be %x, but was %x", 16'h2002, cmd);
			$stop;
		end else
			$display("PASSED TEST 1 - vertical cmd correctly asserted");
		
		@(posedge clk) clr_cmd_rdy = 1;
		@(posedge clk) clr_cmd_rdy = 0;
		repeat(5) @(posedge clk);
		
		// Check horizontal
		@(posedge clk) send_resp = 1;
		@(posedge clk) send_resp = 0;
		if (cmd !== 16'h2BF2) begin
			$display("FAILED TEST 2 - horizontal cmd should be 16'h23F1, but was %x", cmd);
			$stop;
		end else
			$display("PASSED TEST 2 - horizontal cmd correctly asserted");
		
		$display("All tests passed.");
		$stop;
	end
	
	
	always
		#5 clk = ~clk;


endmodule