
module Decoder_7seg (
  input  logic  [0:0] clk_in, rst_n,
  input  logic  [0:0] CS,
  //input  logic [31:0] dbus_addr,
  input  logic [31:0] dbus_in,
  //output logic [31:0] dbus_out,
  output logic  [3:0] an,
  output logic  [6:0] seg
  );

  logic  [3:0] char;
  logic  [7:0] buf8;
  logic [19:0] cnt20;
  
  always_ff @( posedge clk_in ) begin
    if      (!rst_n) buf8 <= '0;
    else if (CS)     buf8 <= dbus_in[7:0];
  end

  // Clock divider (for switching 7seg)
  always_ff @( posedge clk_in ) begin
    if (!rst_n || (cnt20 == '1)) cnt20 <= '0;
    else                         cnt20 <= cnt20 + 1'b1;
  end

  assign an   = !rst_n ? 4'b1111 : cnt20[19] ? 4'b1101 : 4'b1110;
  assign char = cnt20[19] ? buf8[7:4] : buf8[3:0];

  // 7seg decoder
  always_comb begin
    case (char)
      4'h0: seg = 7'b1000000; // 0
      4'h1: seg = 7'b1111001; // 1
      4'h2: seg = 7'b0100100; // 2
      4'h3: seg = 7'b0110000; // 3
      4'h4: seg = 7'b0011001; // 4
      4'h5: seg = 7'b0010010; // 5
      4'h6: seg = 7'b0000010; // 6
      4'h7: seg = 7'b1111000; // 7
      4'h8: seg = 7'b0000000; // 8
      4'h9: seg = 7'b0010000; // 9
      4'ha: seg = 7'b0001000; // A
      4'hb: seg = 7'b0000011; // b
      4'hc: seg = 7'b1000110; // C
      4'hd: seg = 7'b0100001; // d
      4'he: seg = 7'b0000110; // E
      4'hf: seg = 7'b0001110; // F
    endcase
  end  // always_comb

endmodule
