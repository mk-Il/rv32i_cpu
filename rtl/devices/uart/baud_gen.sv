// Baudrate generator module


module BaudGen #(
  parameter NDIV1 = 39,
  parameter NDIV2 = 625
  )(
  input  logic [0:0] clk_in,
  output logic [0:0] tick,     // = BAUDRATE*OSR [Hz]
  output logic [0:0] baud_tick // = BAUDRATE     [Hz]
  );

  localparam NDIV1_LEN = $clog2(NDIV1) + 1;
  localparam NDIV2_LEN = $clog2(NDIV2) + 1;

  logic [NDIV1_LEN-1:0] clk_cnt  = '0;
  logic [NDIV2_LEN-1:0] clk_cnt2 = '0;

  always_ff @( posedge clk_in ) begin
    clk_cnt  <= (clk_cnt  == NDIV1) ? '0 : clk_cnt  + 1'b1;
    clk_cnt2 <= (clk_cnt2 == NDIV2) ? '0 : clk_cnt2 + 1'b1;
  end

  assign tick      = (clk_cnt  == 1);
  assign baud_tick = (clk_cnt2 == 1);

endmodule
