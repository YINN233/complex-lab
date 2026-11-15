`timescale 1ns / 1ps

`default_nettype none

module imm_gen (
    input  wire [31:0] inst,
    input  wire [ 2:0] imm_type,
    output logic [31:0] imm
);

  localparam logic [2:0] IMM_I = 3'd0;
  localparam logic [2:0] IMM_S = 3'd1;
  localparam logic [2:0] IMM_B = 3'd2;
  localparam logic [2:0] IMM_U = 3'd3;
  localparam logic [2:0] IMM_R = 3'd4;

  always_comb begin
    case (imm_type)
      IMM_I:   imm = {{20{inst[31]}}, inst[31:20]};
      IMM_S:   imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
      IMM_B:   imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
      IMM_U:   imm = {inst[31:12], 12'b0};
      IMM_R:   imm = 32'b0;
      default: imm = 32'b0;
    endcase
  end

endmodule

`default_nettype wire
