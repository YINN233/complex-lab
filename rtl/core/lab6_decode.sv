`timescale 1ns / 1ps

module lab6_decode (
    input  logic [31:0] inst_i,
    output lab6_pkg::decode_t control_o,
    output logic [31:0] imm_o
);
  import lab6_pkg::*;

  wire [6:0] opcode = inst_i[6:0];
  wire [2:0] funct3 = inst_i[14:12];
  wire [6:0] funct7 = inst_i[31:25];
  wire [31:0] imm_i = {{20{inst_i[31]}}, inst_i[31:20]};

  always_comb begin
    control_o = '0;
    control_o.op = ALU_ADD;
    control_o.flow = FLOW_NEXT;
    imm_o = '0;

    case (opcode)
      7'h33: begin                        // OP
        control_o.use_rs1 = 1;
        control_o.use_rs2 = 1;
        control_o.write_rd = 1;
        case ({funct7, funct3})
          {7'h00, 3'h0}: control_o.op = ALU_ADD;
          {7'h00, 3'h7}: control_o.op = ALU_AND;
          {7'h00, 3'h6}: control_o.op = ALU_OR;
          {7'h00, 3'h4}: control_o.op = ALU_XOR;
          {7'h00, 3'h3}: control_o.op = ALU_SLTU;
          {7'h14, 3'h1}: control_o.op = ALU_SBSET;
          {7'h24, 3'h1}: control_o.op = ALU_SBCLR;
          default: control_o.illegal = 1;
        endcase
      end
      7'h13: begin                        // OP-IMM
        control_o.use_rs1 = 1;
        control_o.write_rd = 1;
        control_o.b_is_imm = 1;
        imm_o = imm_i;
        case (funct3)
          3'h0: control_o.op = ALU_ADD;
          3'h7: control_o.op = ALU_AND;
          3'h6: control_o.op = ALU_OR;
          3'h1: begin
            if (funct7 == 7'h00) control_o.op = ALU_SLL;
            else if (inst_i[31:20] == 12'h600) control_o.op = ALU_CLZ;
            else control_o.illegal = 1;
          end
          3'h5: begin
            control_o.op = ALU_SRL;
            control_o.illegal = (funct7 != 7'h00);
          end
          default: control_o.illegal = 1;
        endcase
      end
      7'h37, 7'h17: begin                // LUI, AUIPC
        control_o.write_rd = 1;
        control_o.b_is_imm = 1;
        control_o.a_is_pc = (opcode == 7'h17);
        control_o.op = (opcode == 7'h17) ? ALU_ADD : ALU_LUI;
        imm_o = {inst_i[31:12], 12'b0};
      end
      7'h63: begin                        // BEQ, BNE
        control_o.use_rs1 = 1;
        control_o.use_rs2 = 1;
        control_o.flow = (funct3 == 3'h0) ? FLOW_BEQ : FLOW_BNE;
        control_o.illegal = (funct3 != 3'h0 && funct3 != 3'h1);
        imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7],
                 inst_i[30:25], inst_i[11:8], 1'b0};
      end
      7'h6f: begin                        // JAL
        control_o.write_rd = 1;
        control_o.flow = FLOW_JAL;
        imm_o = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12],
                 inst_i[20], inst_i[30:21], 1'b0};
      end
      7'h67: begin                        // JALR
        control_o.use_rs1 = 1;
        control_o.write_rd = 1;
        control_o.flow = FLOW_JALR;
        control_o.illegal = (funct3 != 3'h0);
        imm_o = imm_i;
      end
      7'h03: begin                        // LB, LW
        control_o.use_rs1 = 1;
        control_o.write_rd = 1;
        control_o.b_is_imm = 1;
        control_o.load = 1;
        control_o.byte_access = (funct3 == 3'h0);
        control_o.illegal = (funct3 != 3'h0 && funct3 != 3'h2);
        imm_o = imm_i;
      end
      7'h23: begin                        // SB, SW
        control_o.use_rs1 = 1;
        control_o.use_rs2 = 1;
        control_o.b_is_imm = 1;
        control_o.store = 1;
        control_o.byte_access = (funct3 == 3'h0);
        control_o.illegal = (funct3 != 3'h0 && funct3 != 3'h2);
        imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
      end
      default: control_o.illegal = 1;
    endcase
  end
endmodule
