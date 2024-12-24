module sponge_tb();

    // Testbench signals
    logic clk;
    logic rst_n;
    logic go;
    logic piezo;
    logic piezo_n;
	
	parameter FAST_SIM = 1;	// used to speed up simulation


    // Instantiate the DUT 
    sponge spongeDUT (.clk(clk), .rst_n(rst_n), .go(go), .piezo(piezo), .piezo_n(piezo_n));

    // Clock generation: 10ns period (100 MHz clock)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test procedure
    initial begin
        // Initialize signals
        rst_n = 0;
        go = 0;

        // Apply reset
        @(posedge clk);
		@(negedge clk);
        rst_n = 1;     // Deassert reset

        // Verify that piezo and piezo_n are not toggling before go is asserted
        #10;   
        assert(piezo === 1'bx & piezo_n === 1'bx) else $error("Error: piezo signals toggling before go is asserted!");

        // Assert go to start the tune
        #5000;
        go = 1;
		

        // Wait for some time to let the tune play
        repeat (100) @(posedge clk);
        go = 0;        // Deassert go after a short period

        // Wait for the tune to complete (depends on FAST_SIM parameter)
        #50_000_000;

        // Verify that piezo and piezo_n are not toggling after the tune has completed
        #10;           // Give a little time for signals to settle
        assert(piezo === 1'bx && piezo_n === 1'bx) else $error("Error: piezo signals toggling after tune has completed!");

        // End the simulation
        $display("Test completed successfully.");
        $stop();
    end

endmodule

