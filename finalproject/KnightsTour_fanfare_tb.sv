`timescale 1ns/1ps
module KnightsTour_fanfare_tb();

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

    ///////////////////////////
    // testbench formatting. //
    ///////////////////////////
    print_test_section_footer(1);
    print_test_section_header(2, "Down 2 Command");

    // send a command to move down two squares.
    send_command(16'h47F2, clk, cmd, send_cmd, iRMT.cmd_sent);

    // verify that the robot turns down.
    fork
      assert_move_command_turn_valid(20'sh7F000, iPHYS.heading_robot, clk, iDUT.iCMD.error_meets_threshold);
      assert_cntr_ir_crossed(cntrIR_n, clk);
      assert_resp(8'hA5, iRMT.resp, clk, iDUT.iCMD.send_resp, iRMT.resp_rdy);
    join

    // verify that the robot moves down.
    assert_position_valid(iPHYS.xx, iPHYS.yy, 15'h27F1, 15'h09BC);

    print_test_section_footer(2);
    print_test_section_header(3, "Right 1 Command");

    // send a command to move right one square
    send_command(16'h4BF1, clk, cmd, send_cmd, iRMT.cmd_sent);

    // verify that the robot turns right.
    fork
      assert_move_command_turn_valid(20'shBF000, iPHYS.heading_robot, clk, iDUT.iCMD.error_meets_threshold);
      assert_cntr_ir_crossed(cntrIR_n, clk);
      assert_resp(8'hA5, iRMT.resp, clk, iDUT.iCMD.send_resp, iRMT.resp_rdy);
    join

    // verify that the robot moves right.
    assert_position_valid(iPHYS.xx, iPHYS.yy, 15'h3656, 15'h08EF);

    

    //UP 2 and LEFT 1 CMD
    print_test_section_footer(3);
    print_test_section_header(4, "North 2 Command");

    // send a command to move up two squares.
    send_command(16'h4002, clk, cmd, send_cmd, iRMT.cmd_sent);

    // verify that the robot turns up.
    fork
      assert_move_command_turn_valid(20'sh00000, iPHYS.heading_robot, clk, iDUT.iCMD.error_meets_threshold);
      assert_cntr_ir_crossed(cntrIR_n, clk);
      assert_resp(8'hA5, iRMT.resp, clk, iDUT.iCMD.send_resp, iRMT.resp_rdy);
    join

    // verify that the robot moves up.
    assert_position_valid(iPHYS.xx, iPHYS.yy, 15'h38EF, 15'h2655);

    print_test_section_footer(4);
    print_test_section_header(5, "Left 1 Command");

    // send a command to move left one square
    send_command(16'h43F1, clk, cmd, send_cmd, iRMT.cmd_sent);

    // verify that the robot turns left.
    fork
      assert_move_command_turn_valid(20'sh3F000, iPHYS.heading_robot, clk, iDUT.iCMD.error_meets_threshold);
      assert_cntr_ir_crossed(cntrIR_n, clk);
      assert_resp(8'hA5, iRMT.resp, clk, iDUT.iCMD.send_resp, iRMT.resp_rdy);
    join

    // verify that the robot moves left.
    //assert_position_valid(iPHYS.xx, iPHYS.yy, 15'h2800, 15'h2800);
    assert_position_valid(iPHYS.xx, iPHYS.yy, 15'h298B, 15'h27FE);

    //UP 2 and Right 1 CMD
    print_test_section_footer(5);
    print_test_section_header(6, "North 2 Command");

    // send a command to move up two squares.
    send_command(16'h4002, clk, cmd, send_cmd, iRMT.cmd_sent);

    // verify that the robot turns up.
    fork
      assert_move_command_turn_valid(20'sh00000, iPHYS.heading_robot, clk, iDUT.iCMD.error_meets_threshold);
      assert_cntr_ir_crossed(cntrIR_n, clk);
      assert_resp(8'hA5, iRMT.resp, clk, iDUT.iCMD.send_resp, iRMT.resp_rdy);
    join

    // verify that the robot moves up.
    assert_position_valid(iPHYS.xx, iPHYS.yy, 15'h28EF, 15'h4632);


    print_test_section_footer(6);
    print_test_section_header(7, "Right 1 Command");

    // send a command to move right one square with FANFARE
    send_command(16'h5BF1, clk, cmd, send_cmd, iRMT.cmd_sent);

    // verify that the robot turns right.
    fork
      assert_move_command_turn_valid(20'shBF000, iPHYS.heading_robot, clk, iDUT.iCMD.error_meets_threshold);
      assert_cntr_ir_crossed(cntrIR_n, clk);
      assert_resp(8'hA5, iRMT.resp, clk, iDUT.iCMD.send_resp, iRMT.resp_rdy);
    join

    //Check whether sponge tune plays at the right time
    assert_sponge_valid(clk, iDUT.ISPNG.piezo, iDUT.ISPNG.piezo_n);
    // verify that the robot moves right.
    assert_position_valid(iPHYS.xx, iPHYS.yy, 15'h3661, 15'h482C);

    

    print_test_section_footer(7);




    $display("All tests passed");
    $stop();
  end

  always
    #5 clk = ~clk;

endmodule
