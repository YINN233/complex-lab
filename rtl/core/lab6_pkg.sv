`timescale 1ns / 1ps

package lab6_pkg;
  typedef enum logic [3:0] {
    ALU_ADD, ALU_AND, ALU_OR, ALU_XOR, ALU_SLL, ALU_SRL, ALU_SLTU,
    ALU_LUI, ALU_SBSET, ALU_SBCLR, ALU_CLZ
  } alu_op_t;

  typedef enum logic [2:0] {
    FLOW_NEXT, FLOW_BEQ, FLOW_BNE, FLOW_JAL, FLOW_JALR
  } flow_t;

  typedef enum logic [2:0] {
    SYS_NONE, SYS_CSR_WRITE, SYS_CSR_SET, SYS_CSR_CLEAR, SYS_ECALL, SYS_EBREAK, SYS_MRET
  } system_op_t;

  typedef struct packed {
    alu_op_t op;
    flow_t flow;
    system_op_t system_op;
    logic csr_immediate;
    logic illegal;
    logic use_rs1;
    logic use_rs2;
    logic write_rd;
    logic a_is_pc;
    logic b_is_imm;
    logic load;
    logic store;
    logic byte_access;
  } decode_t;
endpackage
