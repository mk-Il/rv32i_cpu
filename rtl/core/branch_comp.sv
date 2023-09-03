// Branch comparator


module BranchComp (
  input  logic signed [31:0] rs1, rs2,
  input  logic         [2:0] funct3,
  output logic         [0:0] br_taken  // branch taken?
  );

  // Comparator
  wire [0:0] is_eq  = (rs1 == rs2);
  wire [0:0] is_lt  = (rs1 < rs2);
  wire [0:0] is_ltu = (unsigned'(rs1) < unsigned'(rs2));

  // Take the branch or not
  always_comb begin
    case (funct3)
      3'b000:  br_taken =  is_eq;  // BEQ
      3'b001:  br_taken = !is_eq;  // BNE
      3'b100:  br_taken =  is_lt;  // BLT
      3'b101:  br_taken = !is_lt;  // BGE
      3'b110:  br_taken =  is_ltu; // BLTU
      3'b111:  br_taken = !is_ltu; // BGEU
      default: br_taken = 1'b0;
    endcase
  end

endmodule
