module rst_synch(
	input logic RST_n, clk,
	output logic rst_n
	);
	
	//internal rst_n
	logic rst_n1;
	
	//flop 1 for rst_n
	always_ff @(posedge clk, negedge RST_n) begin
		if(!RST_n)
			rst_n1 <= 1'b0;
		else
			rst_n1 <= 1'b1;
	end
	
	always @(negedge clk, negedge RST_n) begin
		if(!RST_n)
			rst_n <= 1'b0;
		else
			rst_n <= rst_n1;
	end
endmodule
