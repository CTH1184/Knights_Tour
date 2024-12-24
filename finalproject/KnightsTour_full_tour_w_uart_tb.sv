`timescale 1ns/1ps
module KnightsTour_full_tour_w_uart_tb();

  import knights_tour_tasks::*; // import all tasks.

  localparam FAST_SIM = 1;

  /////////////////////////////
  // Stimulus of type reg //
  /////////////////////////
  logic clk, RST_n;
  logic [15:0] cmd;
  logic send_cmd;

  ///////////////////////////////////
  // Declare any internal signals //
  /////////////////////////////////
  logic SS_n,SCLK,MOSI,MISO,INT;
  logic lftPWM1,lftPWM2,rghtPWM1,rghtPWM2;
  logic TX_RX, RX_TX;
  logic cmd_sent;
  logic resp_rdy;
  logic [7:0] resp;
  logic IR_en;
  logic lftIR_n,rghtIR_n,cntrIR_n;

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  KnightsTour iDUT(.clk(clk), .RST_n(RST_n), .SS_n(SS_n), .SCLK(SCLK),
                   .MOSI(MOSI), .MISO(MISO), .INT(INT), .lftPWM1(lftPWM1),
				   .lftPWM2(lftPWM2), .rghtPWM1(rghtPWM1), .rghtPWM2(rghtPWM2),
				   .RX(TX_RX), .TX(RX_TX), .piezo(piezo), .piezo_n(piezo_n),
				   .IR_en(IR_en), .lftIR_n(lftIR_n), .rghtIR_n(rghtIR_n),
				   .cntrIR_n(cntrIR_n));

  /////////////////////////////////////////////////////
  // Instantiate RemoteComm to send commands to DUT //
  ///////////////////////////////////////////////////
  RemoteComm iRMT(.clk(clk), .rst_n(RST_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd),
             .send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp));

  //////////////////////////////////////////////////////
  // Instantiate model of Knight Physics (and board) //
  ////////////////////////////////////////////////////
  KnightPhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                      .MOSI(MOSI),.INT(INT),.lftPWM1(lftPWM1),.lftPWM2(lftPWM2),
					  .rghtPWM1(rghtPWM1),.rghtPWM2(rghtPWM2),.IR_en(IR_en),
					  .lftIR_n(lftIR_n),.rghtIR_n(rghtIR_n),.cntrIR_n(cntrIR_n));


  //////////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////// END MODULE INSTANTIATION //////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////


  initial begin
    init_signals(clk, RST_n, cmd, send_cmd);

    // Check that things are initialized correctly.
    $display("####### BEGIN TESTS  #######\n");

    print_test_section_header(1, "Signal Initialization");
    // Are PWM's running and midrail values just after reset?
    // $display("TEST 1 - Manually verify PWM duty cycle is 0.5");

    assert_iNEMO_setup(iPHYS.iNEMO.NEMO_setup, clk);

    // send start_cal. verify cal_done and a positive ACK.
    send_command(CMD_OP_START_CAL, clk, cmd, send_cmd, iRMT.cmd_sent);

    fork
      assert_cal_done(iDUT.cal_done, clk);
      assert_resp(8'hA5, iRMT.resp, clk, iDUT.iCMD.send_resp, iRMT.resp_rdy);
    join

    // Move up 2
    print_test_section_footer(1);
    print_test_section_header(2, "Up 2 command");
    send_command(16'h4002, clk, cmd, send_cmd, iRMT.cmd_sent);
    fork
      assert_move_command_turn_valid(20'sh00000, iPHYS.heading_robot, clk, iDUT.iCMD.error_meets_threshold);
      assert_cntr_ir_crossed(cntrIR_n, clk);
      assert_resp(8'hA5, iRMT.resp, clk, iDUT.iCMD.send_resp, iRMT.resp_rdy);
    join
    assert_position_valid(iPHYS.xx, iPHYS.yy, 15'h2800, 15'h4800);

    // Move right 1
    print_test_section_footer(2);
    print_test_section_header(3, "Right 2 Command");
    send_command(16'h4BF2, clk, cmd, send_cmd, iRMT.cmd_sent);
    fork
      assert_move_command_turn_valid(20'shBF000, iPHYS.heading_robot, clk, iDUT.iCMD.error_meets_threshold);
      assert_cntr_ir_crossed(cntrIR_n, clk);
      assert_resp(8'hA5, iRMT.resp, clk, iDUT.iCMD.send_resp, iRMT.resp_rdy);
    join
    assert_position_valid(iPHYS.xx, iPHYS.yy, 15'h4800, 15'h4800);

    print_test_section_footer(3);
    print_test_section_header(4, "Send Tour");

    // Start tour command, OR'ed with 43 to set starting position correctly
    send_command(CMD_OP_START_TOUR | 16'h0044, clk, cmd, send_cmd, iRMT.cmd_sent);

    print_test_section_footer(4);

  end

  always
    #5 clk = ~clk;

endmodule
