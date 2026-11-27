`timescale 1ns / 1ps

module lab6_trap (
    input  logic                clk_i,
    input  logic                rst_i,
    input  logic                execute_i,
    input  logic [31:0]         pc_i,
    input  logic [31:0]         inst_i,
    input  lab6_pkg::system_op_t system_op_i,
    input  logic [31:0]         csr_operand_i,
    input  logic                illegal_inst_i,
    input  logic                misaligned_target_i,
    input  logic [31:0]         branch_target_i,
    input  logic                misaligned_load_i,
    input  logic                misaligned_store_i,
    input  logic [31:0]         data_addr_i,
    input  logic                timer_irq_i,
    input  logic                uart_irq_i,
    output logic [31:0]         csr_value_o,
    output logic                csr_access_o,
    output logic                trap_o,
    output logic                illegal_trap_o,
    output logic                mret_o,
    output logic [31:0]         target_o
);
  import lab6_pkg::*;

  localparam [11:0] MSTATUS = 12'h300, MIE = 12'h304, MTVEC = 12'h305,
                    MSCRATCH = 12'h340, MEPC = 12'h341, MCAUSE = 12'h342,
                    MTVAL = 12'h343, MIP = 12'h344,
                    PMPCFG0 = 12'h3a0, PMPADDR0 = 12'h3b0;

  // A single bit distinguishes M and U. Only the implemented mstatus fields are writable.
  logic machine_mode, mpp_machine, mpie, mie_global;
  logic meie, mtie;
  logic [31:0] mtvec, mscratch, mepc, mcause, mtval;
  logic [11:0] csr_addr;
  logic [31:0] csr_next, trap_value;
  logic csr_present, csr_write, illegal_csr, illegal_inst;
  logic interrupt_enabled, external_pending, timer_pending, interrupt_taken;
  logic trap_pending;
  logic [3:0] cause_code;

  assign csr_addr = inst_i[31:20];
  assign csr_access_o = system_op_i == SYS_CSR_WRITE ||
                        system_op_i == SYS_CSR_SET || system_op_i == SYS_CSR_CLEAR;
  assign csr_write = system_op_i == SYS_CSR_WRITE || (csr_access_o && inst_i[19:15] != 0);

  always_comb begin
    csr_present = 1;
    csr_value_o = '0;
    case (csr_addr)
      MSTATUS: csr_value_o = {19'b0, {2{mpp_machine}}, 3'b0, mpie, 3'b0, mie_global, 3'b0};
      MIE: csr_value_o = {20'b0, meie, 3'b0, mtie, 7'b0};
      MTVEC: csr_value_o = mtvec;
      MSCRATCH: csr_value_o = mscratch;
      MEPC: csr_value_o = mepc;
      MCAUSE: csr_value_o = mcause;
      MTVAL: csr_value_o = mtval;
      MIP: csr_value_o = {20'b0, uart_irq_i, 3'b0, timer_irq_i, 7'b0};
      // The course monitor probes these on boot. This core implements no PMP regions.
      PMPCFG0, PMPADDR0: ;
      default: csr_present = 0;
    endcase
  end

  always_comb begin
    case (system_op_i)
      SYS_CSR_SET: csr_next = csr_value_o | csr_operand_i;
      SYS_CSR_CLEAR: csr_next = csr_value_o & ~csr_operand_i;
      default: csr_next = csr_operand_i;
    endcase
  end

  assign illegal_csr = csr_access_o && (!machine_mode || !csr_present);
  assign illegal_inst = illegal_inst_i || illegal_csr ||
                        (system_op_i == SYS_MRET && !machine_mode);
  assign interrupt_enabled = !machine_mode || mie_global;
  assign external_pending = uart_irq_i && meie && interrupt_enabled;
  assign timer_pending = timer_irq_i && mtie && interrupt_enabled;
  assign interrupt_taken = external_pending || timer_pending;

  always_comb begin
    trap_pending = 1;
    cause_code = '0;
    trap_value = '0;
    if (external_pending) begin
      cause_code = 11;
    end else if (timer_pending) begin
      cause_code = 7;
    end else if (illegal_inst) begin
      cause_code = 2;
      trap_value = inst_i;
    end else if (misaligned_target_i) begin
      trap_value = branch_target_i;
    end else if (misaligned_load_i || misaligned_store_i) begin
      cause_code = misaligned_store_i ? 4'd6 : 4'd4;
      trap_value = data_addr_i;
    end else if (system_op_i == SYS_ECALL) begin
      cause_code = machine_mode ? 4'd11 : 4'd8;
    end else if (system_op_i == SYS_EBREAK) begin
      cause_code = 3;
      trap_value = pc_i;
    end else begin
      trap_pending = 0;
    end
  end

  assign trap_o = execute_i && trap_pending;
  assign illegal_trap_o = trap_o && !interrupt_taken && illegal_inst;
  assign mret_o = execute_i && !trap_o && system_op_i == SYS_MRET;
  assign target_o = mret_o ? mepc :
                    {mtvec[31:2], 2'b00} +
                    ((mtvec[0] && interrupt_taken) ? {26'b0, cause_code, 2'b00} : 32'b0);

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      machine_mode <= 1;
      mpp_machine <= 0;
      mpie <= 0;
      mie_global <= 0;
      meie <= 0;
      mtie <= 0;
      mtvec <= '0;
      mscratch <= '0;
      mepc <= '0;
      mcause <= '0;
      mtval <= '0;
    end else if (trap_o) begin
      mepc <= pc_i;
      mcause <= {interrupt_taken, 27'b0, cause_code};
      mtval <= trap_value;
      mpp_machine <= machine_mode;
      mpie <= mie_global;
      mie_global <= 0;
      machine_mode <= 1;
    end else if (mret_o) begin
      machine_mode <= mpp_machine;
      mpp_machine <= 0;
      mie_global <= mpie;
      mpie <= 1;
    end else if (execute_i && csr_write) begin
      case (csr_addr)
        MSTATUS: begin
          mpp_machine <= &csr_next[12:11];
          mpie <= csr_next[7];
          mie_global <= csr_next[3];
        end
        MIE: begin
          meie <= csr_next[11];
          mtie <= csr_next[7];
        end
        MTVEC: mtvec <= {csr_next[31:2], 1'b0, csr_next[1:0] == 2'b01};
        MSCRATCH: mscratch <= csr_next;
        MEPC: mepc <= {csr_next[31:2], 2'b00};
        MCAUSE: mcause <= csr_next;
        MTVAL: mtval <= csr_next;
        default: ; // MIP pending bits are driven by the interrupt sources.
      endcase
    end
  end
endmodule
