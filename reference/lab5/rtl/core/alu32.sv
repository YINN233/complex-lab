`timescale 1ns / 1ps

`default_nettype none

module alu32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [ 2:0] op,
    output logic [31:0] y,
    output logic        zero
);

  localparam logic [2:0] ALU_ADD    = 3'd0;
  localparam logic [2:0] ALU_SUB    = 3'd1;
  localparam logic [2:0] ALU_AND    = 3'd2;
  localparam logic [2:0] ALU_OR     = 3'd3;
  localparam logic [2:0] ALU_XOR    = 3'd4;
  localparam logic [2:0] ALU_PASS_B = 3'd5;

  always_comb begin
    case (op)
      ALU_ADD:    y = a + b;
      ALU_SUB:    y = a - b;
      ALU_AND:    y = a & b;
      ALU_OR:     y = a | b;
      ALU_XOR:    y = a ^ b;
      ALU_PASS_B: y = b;
      default:    y = 32'b0;
    endcase
  end

  assign zero = (y == 32'b0);

endmodule

`default_nettype wire
