// RAM module
//
// - dual port (port A: rw, port B: read only)
// - byte addressing, 32-bit bus
// - little endian

module DataRAM #(
  parameter RAM_SIZE = 4*1024
  )(
  input  logic  [0:0] clk_in,
  input  logic  [0:0] CS,
  input  logic  [3:0] we4,
  input  logic [31:0] addrA,
  input  logic [31:0] dinA,
  output logic [31:0] doutA,
  input  logic [31:0] addrB,
  output logic [31:0] doutB
  );

  (* ram_style = "distributed" *)
  logic [31:0] RAM [(RAM_SIZE/4)-1:0];

  wire [31:0] _addrA = {2'b00, addrA[31:2]};  
  wire [31:0] _addrB = {2'b00, addrB[31:2]};

  initial begin
    for (int i = 0; i < RAM_SIZE; i++) RAM[i] <= '0;
    //$readmemh("dmem_data.hex", RAM);
  end

  assign doutA = {<<8{RAM[_addrA]}}; // little endian
  assign doutB = {<<8{RAM[_addrB]}}; // little endian

  always_ff @( posedge clk_in ) begin
    if (CS) begin
      if (we4[0]) RAM[_addrA][31:24] <= dinA[7:0];
      if (we4[1]) RAM[_addrA][23:16] <= dinA[15:8];
      if (we4[2]) RAM[_addrA][15:8]  <= dinA[23:16];
      if (we4[3]) RAM[_addrA][7:0]   <= dinA[31:24];
    end
  end

endmodule
