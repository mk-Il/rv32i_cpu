

module rv32icpu_basys3_wrapper(
  input  logic [0:0] CLK, RST,
  input  logic [0:0] RsRx,
  output logic [0:0] RsTx,
  output logic [1:0] LED,
  output logic [3:0] AN,
  output logic [6:0] SEG
  );
  
  RV32I_CPU rv32i_cpu (
    .clk_in  (CLK),
    .rst     (RST),
    .an      (AN),
    .seg     (SEG),
    .rx      (RsRx),
    .tx      (RsTx)
    //.rx_busy (LED[0]),
    //.tx_busy (LED[1])
  );
  
endmodule
