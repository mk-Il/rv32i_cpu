// Immediate extender


module ImmExt32 (
  input  logic  [5:0] inst_type,
  input  logic [24:0] inst25,
  output logic [31:0] signimm32
  );

  wire [24:0] i = inst25;

  always_comb begin
    case (inst_type)
      6'b000010: signimm32 = {{21{i[24]}},i[23:18],i[4:0]};             // S-type
      6'b000100: signimm32 = {{20{i[24]}},i[0],i[23:18],i[4:1],1'b0};   // B-type
      6'b001000: signimm32 = {i[24:5],{12{1'b0}}};                      // U-type
      6'b010000: signimm32 = {{12{i[24]}},i[12:5],i[13],i[23:14],1'b0}; // J-type
      6'b100000: signimm32 = {{21{i[24]}},i[23:13]};                    // I-type
      6'b000001: signimm32 = '0;                                        // R-type
      default:   signimm32 = '0;
    endcase
  end

endmodule
