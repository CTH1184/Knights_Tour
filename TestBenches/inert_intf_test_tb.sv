module inert_intf_test_tb #(
    parameter CLK_PERIOD = 10
);

    // Inputs
    logic clk;
    logic RST_n;
    logic INT;
    

    // Outputs
    logic SS_n;
    logic SCLK;
    logic MOSI;
    logic MISO;
    logic [7:0] LED;

    //internal signals
  

    // Instantiate the Device Under Test (UUT)
    inert_intf_test DUT (
        .clk(clk),
        .RST_n(RST_n),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .INT(INT),
        .LED(LED)
    );

    SPI_iNEMO2 iSPI (
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MISO(MISO),
        .MOSI(MOSI),
        .INT(INT)
    );


    // Clock
    always #10 clk = ~clk;

    ////////////////////
    // Testbench Code //
    ////////////////////
    initial begin
        RST_n = 0;
        clk = 0;

        // lift reset
        @(negedge clk) RST_n = 1;

        $display("-----------------------");
        $display("--------TEST 1---------");

        // wait for NEMO_setup to be asserted
        fork: wait_for_NEMO_setup
            begin : timeout
                repeat (1000000) @(posedge clk);
                $display("Test Failed! SPI_iNEMO2.NEMO_setup was not asserted in time!");
                disable success;
                $stop();
            end

            begin : success
                @(posedge iSPI.NEMO_setup) disable timeout;
            end
        join


        // wait for cal_done to be asserted
        fork: wait_for_cal_done
            begin : timeout
                repeat (1000000) @(posedge clk);
                $display("Test Failed! cal_done was not asserted in time!");
                disable success;
                $stop();
            end

            begin : success
                @(posedge DUT.cal_done) disable timeout;
            end
        join

        $display("-----------------------");
        $display("--------TEST 2---------");


        repeat (8000000) @(negedge clk);

        $display("YAHOO! Tests Passed!");
        $stop();

    end


    // clock generation
    always @(clk) #(CLK_PERIOD / 2) clk <= ~clk;


endmodule