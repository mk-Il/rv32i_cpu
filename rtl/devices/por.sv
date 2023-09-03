// Power On Reset

module POR(
  input  logic clk, rst_n,
  output logic rst_out
  );
  
  logic [7:0] buf8 = '1;
  always_ff @( posedge clk ) buf8 <= {buf8[6:0], rst_n};
  assign rst_out = (buf8 == 8'b0);

endmodule