module sponge_test(clk,RST_n,GO,piezo,piezo_n);

  // Signals
  input clk;
  input RST_n;
  input GO;
  output piezo;
  output piezo_n;
  
  //Internal signals
  logic go;
  logic rst_n;
  parameter FAST_SIM = 0;
  

  // Instantiate the modules
  sponge #(FAST_SIM) iSponge (
    .clk(clk),
    .rst_n(rst_n),
    .go(go),
    .piezo(piezo),
    .piezo_n(piezo_n)
  );

  PB_release pb_DUT(
    .clk(clk),
    .rst_n(rst_n),
    .PB(GO),
    .released(go)
  );

  reset_synch reset_DUT (
    .clk(clk),
    .RST_n(RST_n),
    .rst_n(rst_n)
  );


endmodule