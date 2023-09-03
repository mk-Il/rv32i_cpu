// Instruction memory module (ROM)

module InstROM #(
  parameter ROM_SIZE = 4*1024 // 4 KB
  )(
  input  logic [31:0] addrA,
  input  logic [31:0] addrB,
  output logic [31:0] doutA,
  output logic [31:0] doutB
  );

  (* rom_style="distributed" *)
  logic [31:0] ROM [0:(ROM_SIZE/4)-1];

  initial begin
    //for (int i = 0; i < ROM_SIZE; i++) ROM[i] <= '0;
    $readmemh("program_loader.hex", ROM);
  end

  wire [31:0] _addrA = {2'b00, addrA[31:2]};  
  wire [31:0] _addrB = {2'b00, addrB[31:2]};

  assign doutA = {<<8{ROM[_addrA]}}; // little endian
  assign doutB = {<<8{ROM[_addrB]}}; // little endian

endmodule
