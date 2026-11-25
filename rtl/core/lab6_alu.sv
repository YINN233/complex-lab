`timescale 1ns / 1ps

module lab6_alu (
    input  lab6_pkg::alu_op_t op_i,
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    output logic [31:0] result_o
);
  import lab6_pkg::*;

  function automatic logic [5:0] leading_zeros(input logic [31:0] value);
    logic [15:0] half_word;
    logic [7:0] octet;
    logic [3:0] nibble;
    logic [1:0] pair;
    logic [4:0] count;
    count[4] = (value[31:16] == 0);
    half_word = count[4] ? value[15:0] : value[31:16];
    count[3] = (half_word[15:8] == 0);
    octet = count[3] ? half_word[7:0] : half_word[15:8];
    count[2] = (octet[7:4] == 0);
    nibble = count[2] ? octet[3:0] : octet[7:4];
    count[1] = (nibble[3:2] == 0);
    pair = count[1] ? nibble[1:0] : nibble[3:2];
    count[0] = !pair[1];
    return (value == 0) ? 6'd32 : {1'b0, count};
  endfunction

  always_comb begin
    case (op_i)
      ALU_ADD:   result_o = a_i + b_i;
      ALU_AND:   result_o = a_i & b_i;
      ALU_OR:    result_o = a_i | b_i;
      ALU_XOR:   result_o = a_i ^ b_i;
      ALU_SLL:   result_o = a_i << b_i[4:0];
      ALU_SRL:   result_o = a_i >> b_i[4:0];
      ALU_SLTU:  result_o = {31'b0, a_i < b_i};
      ALU_LUI:   result_o = b_i;
      ALU_SBSET: result_o = a_i |  (32'b1 << b_i[4:0]);
      ALU_SBCLR: result_o = a_i & ~(32'b1 << b_i[4:0]);
      ALU_CLZ:   result_o = {26'b0, leading_zeros(a_i)};
      default:   result_o = '0;
    endcase
  end
endmodule
