module cmd_proc_tb();
    logic clk, rst_n;

    /* RemoteComm signals */
    logic snd_cmd, resp_rdy, TX_RX, cmd_snt;
    logic [15:0] input_cmd;
    logic [7:0] resp;

    /* UART_wrapper signals */
    logic [15:0] UART_cmd;
    logic cmd_rdy, clr_cmd_rdy, RX_TX;

    /* SPI_iNEMO3 signals */
    logic INT, SS_n, SCLK, MOSI, MISO;

    /* inert_intf signals */
    logic heading_rdy, cal_done;
    logic [11:0] heading;

    /* cmd_proc signals */
    logic fanfare_go, send_resp, tour_go, strt_cal, moving, cntrIR, lftIR;
    logic [9:0] frwrd;
    logic [11:0] error;

    /**************************************************
    Instantiate RemoteComm
    **************************************************/
    RemoteComm iRemoteComm(
        .clk(clk),
        .rst_n(rst_n),
        .cmd(input_cmd),
        .snd_cmd(snd_cmd),
        .cmd_snt(cmd_snt),
        .resp(resp),
        .resp_rdy(resp_rdy),
        .TX(TX_RX),
        .RX(RX_TX)
    );

    /**************************************************
    Instantiate UART wrapper
    **************************************************/
    UART_wrapper iUART_wrapper(
        .clk(clk),
        .rst_n(rst_n),
        .RX(TX_RX),
        .TX(RX_TX),
        .resp(8'hA5),
        .trmt(send_resp), // send_resp is trmt?
        .clr_cmd_rdy(clr_cmd_rdy),
        .cmd_rdy(cmd_rdy),
        .cmd(UART_cmd),
        .tx_done()
    );

    /**************************************************
    Instantiate SPI_iNEMO3
    **************************************************/
    SPI_iNEMO3 iSPI_NEMO3(
        .SS_n(SS_n),
        .INT(INT),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO)
    );

    /**************************************************
    Instantiate inert_intf (FAST_SIM = 0)
    **************************************************/
    inert_intf #(1) ii(
        .clk(clk),
        .rst_n(rst_n),
        .strt_cal(strt_cal),
        .lftIR(lftIR),
        .rghtIR(1'b0),
        .cal_done(cal_done),
        .heading(heading),
        .rdy(heading_rdy),
        .moving(moving),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .INT(INT),
        .SS_n(SS_n)
    );

    /**************************************************
    Instantiate cmd_prod
    **************************************************/
    cmd_proc iCMD_PROC(
        .clk(clk),
        .rst_n(rst_n),
        .cmd(UART_cmd),
        .cmd_rdy(cmd_rdy),
        .clr_cmd_rdy(clr_cmd_rdy),
        .send_resp(send_resp),
        .tour_go(tour_go),
        .heading(heading),
        .heading_rdy(heading_rdy),
        .strt_cal(strt_cal),
        .cal_done(cal_done),
        .moving(moving),
        .lftIR(lftIR),
        .cntrIR(cntrIR),
        .rghtIR(1'b0),
        .fanfare_go(fanfare_go),
        .frwrd(frwrd),
        .error(error)
    );

    /**************************************************
    Begin test bench
    **************************************************/
    initial begin
        // Initial default for all inputs before reset
        clk = 0;
        rst_n = 0;
        input_cmd = 0;
        snd_cmd = 0;
        cntrIR = 0;
        lftIR = 0;

        /* Test 1 - Establish all inputs to known values, assert/deassert rst_n */
        @(posedge clk) rst_n = 1;

        /* Test 2 - send calibrate command (0x2000) */
        $display("############ TEST 2 ############");
        input_cmd = 16'h2000;
        @(posedge clk) snd_cmd = 1;
        @(posedge clk) snd_cmd = 0;

        // Wait for cal_done or timeout
        fork
            begin: timeout
                repeat(1000000) @(posedge clk);
                $display("#1 FAILED - cal_done timeout");
                $stop();
            end
            begin
                wait (cal_done);
                $display("#1 PASSED - cal_done asserted");
                disable timeout;
            end
        join

        // Wait for resp_rdy or timeout
        fork
            begin: timeout2
                repeat(1000000) @(posedge clk);
                $display("#2 FAILED - resp_rdy timeout");
                $stop();
            end
            begin
                wait (resp_rdy);
                $display("#2 PASSED - resp_rdy asserted");
                disable timeout2;
            end
        join

        /* Test 3 - send command to move north one square */
        $display("############ TEST 3 ############");
        input_cmd = 16'h4001;
        @(posedge clk) snd_cmd = 1;
        @(posedge clk) snd_cmd = 0;

        // Wait for cmd_snt or timeout
        fork
            begin: timeout3
                repeat(1000000) @(posedge clk);
                $display("#1 FAILED - cmd_sent timeout");
                $stop();
            end
            begin
                wait (cmd_snt);
                $display("#1 PASSED - cmd_sent asserted");
                disable timeout3;
            end
        join

        // wait for cmd_rdy or timeout
        fork
            begin: timeout_rdy_2
                repeat(1000000) @(posedge clk);
                $display("#2 FAILED - cmd_rdy timeout");
                $stop();
            end
            begin
                wait (cmd_rdy);
                $display("#2 PASSED - cmd_rdy asserted");
                disable timeout_rdy_2;
            end
        join

        // Ensure correct value on frwrd
        if (frwrd === 10'h000) begin
            $display("#2 PASSED - frwrd=10'h000 after cmd=16'h4001");
        end else begin
            $display("#2 FAILED - frwrd=%h after cmd=16'h4001", frwrd);
            $stop();
        end

        // Wait for 10 posedges of heading_rdy
        repeat(10) @(posedge heading_rdy);
        if (frwrd === 10'h120) begin
            $display("#3 PASSED - frwrd=10'h120 after 10 posedges of heading_rdy");
        end else begin
            $display("#3 FAILED - frwrd=%h after 10 posedges of heading_rdy", frwrd);
            $stop();
        end
        if (moving) begin
            $display("#4 PASSED - moving asserted after 10 posedges of heading_rdy");
        end else begin
            $display("#4 FAILED - moving=%d after 10 posedges of heading_rdy, should be asserted", frwrd);
            $stop();
        end

        // Wait for 20 more posedges of heading_rdy
        repeat(20) @(posedge heading_rdy);
        if (frwrd === 10'h300) begin
            $display("#5 PASSED - frwd saturated to max speed");
        end else begin
            $display("#5 FAILED - fwrd should be 10'h300, but was %h", frwrd);
            $stop();
        end

        // Give pulse on cntrIR like it crossed a line
        @(posedge clk) cntrIR = 1;
        @(posedge clk) cntrIR = 0;

        // frwrd should remain saturated
        repeat(20) @(posedge clk);
        if (frwrd === 10'h300) begin
            $display("#7 PASSED - frwd remained saturated at max speed");
        end else begin
            $display("#7 FAILED - fwrd should remain saturated, but was %h", frwrd);
            $stop();
        end

        // Give second pulse, like it crossed a second line
        @(posedge clk) cntrIR = 1;
        @(posedge clk) cntrIR = 0;

        // frwrd should ramp down to 0
        fork
            begin: timeout4
                repeat(1000000) @(posedge clk);
                $display("#8 FAILED - fwrd ramp down timeout");
                $stop();
            end
            begin
                wait (frwrd === 0);
                $display("#8 PASSED - frwrd ramp down to 0");
                disable timeout4;
            end
        join

        // Move should end when frwrd hits 0
        fork
            begin: timeout5
                repeat(1000000) @(posedge clk);
                $display("#9 FAILED - resp_rdy should be asserted when done moving");
                $stop();
            end
            begin
                wait (resp_rdy);
                $display("#9 PASSED - resp_rdy timeout when done moving, should have been asserted");
                disable timeout5;
            end
        join

        /* Test 4: send another move north 1 square cmd */
        $display("############ TEST 4 ############");

        input_cmd = 16'h4001;
        @(posedge clk) snd_cmd = 1;
        @(posedge clk) snd_cmd = 0;

        // Wait for cmd_snt or timeout
        fork
            begin: timeout6
                repeat(1000000) @(posedge clk);
                $display("#1 FAILED - cmd_sent timeout");
                $stop();
            end
            begin
                wait (cmd_snt);
                $display("#1 PASSED - cmd_sent asserted");
                disable timeout6;
            end
        join

        // wait for cmd_rdy or timeout
        fork
            begin: timeout_rdy_3
                repeat(1000000) @(posedge clk);
                $display("#2 FAILED - cmd_rdy timeout");
                $stop();
            end
            begin
                wait (cmd_rdy);
                $display("#2 PASSED - cmd_rdy asserted");
                disable timeout_rdy_3;
            end
        join

        // Ensure correct value on frwrd
        if (frwrd === 10'h000) begin
            $display("#2 PASSED - frwrd=10'h000 after cmd=16'h4001");
        end else begin
            $display("#2 FAILED - frwrd=%h after cmd=16'h4001", frwrd);
            $stop();
        end

        // Wait for 10 posedges of heading_rdy
        repeat(10) @(posedge heading_rdy);
        if (frwrd === 10'h120) begin
            $display("#3 PASSED - frwrd=10'h120 after 10 posedges of heading_rdy");
        end else begin
            $strobe("#3 FAILED - frwrd=%h after 10 posedges of heading_rdy", frwrd);
            $stop();
        end

        if (moving) begin
            $display("#4 PASSED - moving asserted after 10 posedges of heading_rdy");
        end else begin
            $display("#4 FAILED - mvoing=%d after 10 posedges of heading_rdy, should be asserted", frwrd);
            $stop();
        end

        // Wait for 20 more posedges of heading_rdy
        repeat(20) @(posedge heading_rdy);
        if (frwrd === 10'h300) begin
            $display("#5 PASSED - frwd saturated to max speed");
        end else begin
            $display("#5 FAILED - fwrd should be 10'h300, but was %h", frwrd);
            $stop();
        end

        // Give pulse on lftIR many clocks in width
        @(posedge clk) lftIR = 1;
        repeat(100) @(posedge clk);
        @(posedge clk) lftIR = 0;

        // Should see significant disturbance in error
        fork
            begin: timeout7
                repeat(1000000) @(posedge clk);
                $display("#6 FAILED - error should be disturbed by lftIR");
                $stop();
            end
            begin
                wait (error != 0);
                $display("#6 PASSED - error disturbed by lftIR");
                disable timeout7;
            end
        join

    $stop();
    end

    /* Drive the clock */
    always @(clk) #5 clk <= ~clk;


endmodule