
module LoadStoreUnit (
  input  logic  [0:0] we,       // write enable
  input  logic  [1:0] wmode,    // funct3[1:0]
  input  logic  [2:0] rmode,    // funct3
  input  logic  [1:0] addr_offset,
  // CPU -> din_cpu  -> store unit -> din2mem  -> memory
  // CPU <- dout2cpu <- load unit  <- dout_mem <- memory
  input  logic [31:0] din_cpu,
  input  logic [31:0] dout_mem,
  output logic  [3:0] we4,      // byte write enable
  output logic [31:0] dout2cpu,
  output logic [31:0] din2mem
  );

  wire [1:0] ofs = addr_offset;

  // ---------------------------------
  // Load unit
  // ---------------------------------
  always_comb begin
    case (rmode)
      3'b010:  dout2cpu = dout_mem; // LW
      3'b000:  dout2cpu = 32'(signed'(dout_mem[ofs*8 +: 8]));   // LB
      3'b100:  dout2cpu = 32'(unsigned'(dout_mem[ofs*8 +: 8])); // LBU
      3'b001:  dout2cpu = (ofs == 3) ? 32'(signed'({dout_mem[7:0],dout_mem[31:24]}))   : 32'(signed'({dout_mem[(ofs+1)*8 +: 8],dout_mem[ofs*8 +: 8]}));   // LH
      3'b101:  dout2cpu = (ofs == 3) ? 32'(unsigned'({dout_mem[7:0],dout_mem[31:24]})) : 32'(unsigned'({dout_mem[(ofs+1)*8 +: 8],dout_mem[ofs*8 +: 8]})); // LHU
      default: dout2cpu = dout_mem;
    endcase
  end

  // ---------------------------------
  // Store unit
  // ---------------------------------
  wire [31:0] din_ext = 32'(unsigned'(din_cpu[15:0]));
  wire  [4:0] shamt   = {3'b0, ofs} << 3; // 0, 8, 16, 24
  // Decode wmode -> we4
  always_comb begin
    case (wmode)
      2'b00:   we4 = {3'b0, we} << ofs; // SB
      2'b01:   we4 = ({2'b0, {2{we}}} << ofs) | ({2'b0, {2{we}}} >> (4-ofs)); // SH. circular shift
      2'b10:   we4 = {4{we}}; // SW
      default: we4 = 4'b0;
    endcase
  end
  
  // Parse din -> din2mem
  always_comb begin
    case (wmode)
      2'b00:   din2mem = {4{din_cpu[7:0]}}; // SB
      2'b01:   din2mem = (din_ext << shamt) | (din_ext >> (32-shamt)); // SH. circular shift (8-bit)
      2'b10:   din2mem = din_cpu; // SW
      default: din2mem = '0;
    endcase
  end

endmodule
