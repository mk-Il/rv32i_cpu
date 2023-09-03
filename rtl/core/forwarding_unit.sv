// Register forwarding unit


module ForwardingUnit (
  input  logic [4:0] rs1addr_e, // rs1addr from execution stage
  input  logic [4:0] rs2addr_e, // rs2addr from execution stage
  input  logic [4:0] rd_m,      // rd from memory access stage
  input  logic [4:0] rd_w,      // write back stage
  input  logic [0:0] regwe_m,   // regfile write enable from memory access stage
  input  logic [0:0] regwe_w,   // write back stage
  input  logic [0:0] csrwe_m,   // CSR write enable from memory access stage
  input  logic [0:0] csrwe_w,   // CSR write enable from write back stage
  output logic [2:0] fwd_sr1_e,
  output logic [2:0] fwd_sr2_e
  );

  // fwd_sr*_e
  // 3'b000: no hazard
  // 3'b010: forward from memory access stage
  // 3'b001: forward from write back stage
  // 3'b100: forward from memory access stage (CSR)
  // 3'b101: forward from write back stage (CSR)
  always_comb begin
    if      (rs1addr_e != '0 && rs1addr_e == rd_m && csrwe_m)
        fwd_sr1_e = 3'b100;
    else if (rs1addr_e != '0 && rs1addr_e == rd_w && csrwe_w)
        fwd_sr1_e = 3'b101;
    else if (rs1addr_e != '0 && rs1addr_e == rd_m && regwe_m)
        fwd_sr1_e = 3'b010;
    else if (rs1addr_e != '0 && rs1addr_e == rd_w && regwe_w)
        fwd_sr1_e = 3'b001;
    else
        fwd_sr1_e = 3'b000;
  end

  always_comb begin
    if      (rs2addr_e != '0 && rs2addr_e == rd_m && csrwe_m)
        fwd_sr2_e = 3'b100;
    else if (rs2addr_e != '0 && rs2addr_e == rd_w && csrwe_w)
        fwd_sr2_e = 3'b101;
    else if (rs2addr_e != '0 && rs2addr_e == rd_m && regwe_m)
        fwd_sr2_e = 3'b010;
    else if (rs2addr_e != '0 && rs2addr_e == rd_w && regwe_w)
        fwd_sr2_e = 3'b001;
    else  
        fwd_sr2_e = 3'b000;
  end

endmodule
