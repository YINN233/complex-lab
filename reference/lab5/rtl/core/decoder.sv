`timescale 1ns / 1ps

`default_nettype none

module decoder (
    input  wire [31:0] inst,
    output logic        reg_we,
    output logic        mem_read,
    output logic        mem_write,
    output logic [ 2:0] alu_op,
    output logic        alu_b_sel,
    output logic        wb_src,
    output logic        branch,
    output logic        mem_size,
    output logic [ 2:0] imm_type,
    output logic [ 4:0] rs1,
    output logic [ 4:0] rs2,
    output logic [ 4:0] rd
);

  localparam logic [6:0] OP_LUI   = 7'b0110111;
  localparam logic [6:0] OP_BEQ   = 7'b1100011;
  localparam logic [6:0] OP_LB    = 7'b0000011;
  localparam logic [6:0] OP_STORE = 7'b0100011;
  localparam logic [6:0] OP_IMM   = 7'b0010011;
  localparam logic [6:0] OP_ADD   = 7'b0110011;

  localparam logic [2:0] ALU_ADD    = 3'd0;
  localparam logic [2:0] ALU_SUB    = 3'd1;
  localparam logic [2:0] ALU_AND    = 3'd2;
  localparam logic [2:0] ALU_PASS_B = 3'd5;

  localparam logic [2:0] IMM_I = 3'd0;
  localparam logic [2:0] IMM_S = 3'd1;
  localparam logic [2:0] IMM_B = 3'd2;
  localparam logic [2:0] IMM_U = 3'd3;
  localparam logic [2:0] IMM_R = 3'd4;

  always_comb begin
    reg_we     = 1'b0;
    mem_read   = 1'b0;
    mem_write  = 1'b0;
    alu_op     = ALU_ADD;
    alu_b_sel  = 1'b0;
    wb_src     = 1'b0;
    branch     = 1'b0;
    mem_size   = 1'b0;
    imm_type   = IMM_R;

    case (inst[6:0])
      OP_LUI: begin
        reg_we    = 1'b1;
        alu_op    = ALU_PASS_B;
        alu_b_sel = 1'b1;
        imm_type  = IMM_U;
      end

      OP_IMM: begin
        case (inst[14:12])
          3'b000: begin
            reg_we    = 1'b1;
            alu_op    = ALU_ADD;
            alu_b_sel = 1'b1;
            imm_type  = IMM_I;
          end
          3'b111: begin
            reg_we    = 1'b1;
            alu_op    = ALU_AND;
            alu_b_sel = 1'b1;
            imm_type  = IMM_I;
          end
          default: ;
        endcase
      end

      OP_ADD: begin
        if ((inst[14:12] == 3'b000) && (inst[31:25] == 7'b0000000)) begin
          reg_we    = 1'b1;
          alu_op    = ALU_ADD;
          alu_b_sel = 1'b0;
          imm_type  = IMM_R;
        end
      end

      OP_LB: begin
        if (inst[14:12] == 3'b000) begin
          reg_we    = 1'b1;
          mem_read  = 1'b1;
          alu_op    = ALU_ADD;
          alu_b_sel = 1'b1;
          wb_src    = 1'b1;
          mem_size  = 1'b0;
          imm_type  = IMM_I;
        end
      end

      OP_STORE: begin
        case (inst[14:12])
          3'b000: begin
            mem_write = 1'b1;
            alu_op    = ALU_ADD;
            alu_b_sel = 1'b1;
            mem_size  = 1'b0;
            imm_type  = IMM_S;
          end
          3'b010: begin
            mem_write = 1'b1;
            alu_op    = ALU_ADD;
            alu_b_sel = 1'b1;
            mem_size  = 1'b1;
            imm_type  = IMM_S;
          end
          default: ;
        endcase
      end

      OP_BEQ: begin
        if (inst[14:12] == 3'b000) begin
          branch    = 1'b1;
          alu_op    = ALU_SUB;
          alu_b_sel = 1'b0;
          imm_type  = IMM_B;
        end
      end

      default: ;
    endcase
  end

  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd  = inst[11:7];

endmodule

`default_nettype wire
