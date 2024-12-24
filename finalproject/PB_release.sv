module PB_release(
	input clk, rst_n, PB,
	output released
	);
	
	
	//internal flop sigs
	logic ff1, ff2, ff3;
	
	//meta stable flops, synchronize input
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			ff1 <= 1'b1;
			ff2 <= 1'b1;
			ff3 <= 1'b1;
		end else begin
			ff1 <= PB;
			ff2 <= ff1;
			ff3 <= ff2;
		end
	end
	
	//rising edge detector
	assign released = (ff2 & ~ff3);
endmodule