// 32-bit ALU
//
// - ignore overflow, no carry flag

module ALU (
  input  logic         [3:0] ctrl,
  input  logic signed [31:0] sr1, sr2,
  output logic        [31:0] out
  );

  always_comb begin
    case (ctrl)
      4'b000_0: out = ADDER(sr1, sr2);                   // ADD
      4'b000_1: out = ADDER(sr1, ~sr2 + 1'b1);           // SUB
      4'b001_0: out = sr1 << sr2[4:0];                   // SLL (Shift Left Logical)
      4'b010_0: out = (sr1 < sr2);                       // SLT (Set Less Than)
      4'b011_0: out = (unsigned'(sr1) < unsigned'(sr2)); // SLTU (Set Less Than Unsigned)
      4'b100_0: out = sr1 ^ sr2;                         // XOR
      4'b101_0: out = sr1 >> sr2[4:0];                   // SRL (Shift Right Logical)
      4'b101_1: out = sr1 >>> sr2[4:0];                  // SRA (Shift Right Arithmetic)
      4'b110_0: out = sr1 | sr2;                         // OR
      4'b111_0: out = sr1 & sr2;                         // AND
      4'b110_1: out = sr1;                               // pass through sr1
      4'b111_1: out = sr2;                               // pass through sr2 (for LUI)
      default:  out = '0;
    endcase
  end

  function [31:0] ADDER;
    input [31:0] op1, op2;
    begin
      ADDER = op1 + op2;
    end
  endfunction

endmodule
