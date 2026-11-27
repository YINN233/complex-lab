`timescale 1ns / 1ps

module lab6_core #(
    parameter logic [31:0] RESET_PC = 32'h8000_0000
) (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        timer_irq_i,
    input  logic        uart_irq_i,
    output logic        imem_req_o,
    output logic [31:0] imem_addr_o,
    input  logic        imem_ack_i,
    input  logic [31:0] imem_rdata_i,
    output logic        dmem_req_o,
    output logic [31:0] dmem_addr_o,
    output logic        dmem_we_o,
    output logic [3:0]  dmem_sel_o,
    output logic [31:0] dmem_wdata_o,
    input  logic        dmem_ack_i,
    input  logic [31:0] dmem_rdata_i,
    output logic        illegal_o,
    output logic [31:0] pc_o,
    output logic        retire_o,
    output logic [31:0] retire_pc_o,
    output logic [31:0] retire_inst_o
);
  import lab6_pkg::*;

  typedef struct packed {
    logic valid;
    logic [31:0] pc, inst;
  } fetch_stage_t;

  typedef struct packed {
    logic valid;
    logic [31:0] pc, inst, imm, rs1_value, rs2_value;
    logic [4:0] rs1, rs2, rd;
    decode_t control;
  } execute_stage_t;

  typedef struct packed {
    logic valid;
    logic [31:0] pc, inst, result, store_data;
    logic [4:0] rd;
    logic write_rd, load, store, byte_access;
  } memory_stage_t;

  typedef struct packed {
    logic valid;
    logic [31:0] pc, inst, result;
    logic [4:0] rd;
    logic write_rd;
  } writeback_stage_t;

  fetch_stage_t if_id;
  execute_stage_t id_ex;
  memory_stage_t ex_mem;
  writeback_stage_t mem_wb;

  logic [31:0] fetch_pc, pending_pc;
  logic fetch_pending, discard_fetch;
  logic issue_fetch, accept_fetch;
  logic [31:0] id_imm, rs1_data, rs2_data;
  logic [4:0] id_rs1, id_rs2;
  decode_t id_control;
  logic load_use, id_advance, mem_can_advance;
  logic wb_write, forward_mem, redirect, flush_front;
  logic [31:0] ex_rs1, ex_rs2, alu_a, alu_b, alu_result;
  logic [31:0] branch_target, redirect_pc, load_result;
  logic [7:0] load_byte;
  logic branch_taken, link_result;
  logic execute, trap, illegal_trap, mret, csr_access, misaligned_data;
  logic [31:0] csr_operand, csr_value, trap_target;

  assign id_rs1 = if_id.inst[19:15];
  assign id_rs2 = if_id.inst[24:20];
  assign wb_write = mem_wb.valid && mem_wb.write_rd && mem_wb.rd != 0;

  regfile32 registers (
      .clk(clk_i), .rst(rst_i),
      .we(wb_write), .waddr(mem_wb.rd), .wdata(mem_wb.result),
      .raddr_a(id_rs1), .rdata_a(rs1_data),
      .raddr_b(id_rs2), .rdata_b(rs2_data)
  );
  lab6_decode decode (
      .inst_i(if_id.inst), .control_o(id_control), .imm_o(id_imm)
  );

  assign forward_mem = ex_mem.valid && ex_mem.write_rd && !ex_mem.load && ex_mem.rd != 0;
  always_comb begin
    ex_rs1 = id_ex.rs1_value;
    if (wb_write && mem_wb.rd == id_ex.rs1) ex_rs1 = mem_wb.result;
    if (forward_mem && ex_mem.rd == id_ex.rs1) ex_rs1 = ex_mem.result;

    ex_rs2 = id_ex.rs2_value;
    if (wb_write && mem_wb.rd == id_ex.rs2) ex_rs2 = mem_wb.result;
    if (forward_mem && ex_mem.rd == id_ex.rs2) ex_rs2 = ex_mem.result;
  end

  assign alu_a = id_ex.control.a_is_pc ? id_ex.pc : ex_rs1;
  assign alu_b = id_ex.control.b_is_imm ? id_ex.imm : ex_rs2;
  lab6_alu alu (.op_i(id_ex.control.op), .a_i(alu_a), .b_i(alu_b), .result_o(alu_result));

  assign link_result = id_ex.control.flow == FLOW_JAL || id_ex.control.flow == FLOW_JALR;
  assign branch_taken = link_result ||
                        (id_ex.control.flow == FLOW_BEQ && ex_rs1 == ex_rs2) ||
                        (id_ex.control.flow == FLOW_BNE && ex_rs1 != ex_rs2);
  assign branch_target = (id_ex.control.flow == FLOW_JALR)
                         ? ((ex_rs1 + id_ex.imm) & 32'hffff_fffe)
                         : (id_ex.pc + id_ex.imm);
  // Resolve traps and CSR writes only when the older MEM instruction can finish.
  // A trap suppresses the EX instruction and all younger instructions.
  assign execute = !rst_i && id_ex.valid && mem_can_advance;
  assign csr_operand = id_ex.control.csr_immediate ? {27'b0, id_ex.rs1} : ex_rs1;
  assign misaligned_data = !id_ex.control.byte_access && (alu_result[1:0] != 0);
  lab6_trap trap_control (
      .clk_i(clk_i), .rst_i(rst_i), .execute_i(execute),
      .pc_i(id_ex.pc), .inst_i(id_ex.inst), .system_op_i(id_ex.control.system_op),
      .csr_operand_i(csr_operand), .illegal_inst_i(id_ex.control.illegal),
      .misaligned_target_i(branch_taken && branch_target[1:0] != 0), .branch_target_i(branch_target),
      .misaligned_load_i(misaligned_data && id_ex.control.load),
      .misaligned_store_i(misaligned_data && id_ex.control.store), .data_addr_i(alu_result),
      .timer_irq_i(timer_irq_i), .uart_irq_i(uart_irq_i),
      .csr_value_o(csr_value), .csr_access_o(csr_access),
      .trap_o(trap), .illegal_trap_o(illegal_trap), .mret_o(mret), .target_o(trap_target)
  );

  assign redirect = trap || mret || (execute && branch_taken);
  assign redirect_pc = (trap || mret) ? trap_target : branch_target;
  assign flush_front = redirect;

  assign dmem_req_o = !rst_i && ex_mem.valid && (ex_mem.load || ex_mem.store);
  assign dmem_addr_o = ex_mem.result;
  assign dmem_we_o = ex_mem.store;
  assign dmem_sel_o = ex_mem.byte_access ? (4'b0001 << dmem_addr_o[1:0]) : 4'b1111;
  assign dmem_wdata_o = ex_mem.byte_access
                       ? ({24'b0, ex_mem.store_data[7:0]} << {dmem_addr_o[1:0], 3'b000})
                       : ex_mem.store_data;
  assign load_byte = dmem_rdata_i[{dmem_addr_o[1:0], 3'b000} +: 8];
  assign load_result = ex_mem.byte_access ? {{24{load_byte[7]}}, load_byte} : dmem_rdata_i;
  assign mem_can_advance = !dmem_req_o || dmem_ack_i;

  assign load_use = if_id.valid && id_ex.valid && id_ex.control.load && id_ex.rd != 0 &&
                    ((id_control.use_rs1 && id_rs1 == id_ex.rd) ||
                     (id_control.use_rs2 && id_rs2 == id_ex.rd));
  assign id_advance = if_id.valid && mem_can_advance && !load_use && !flush_front;
  assign issue_fetch = !rst_i && !fetch_pending && !flush_front &&
                       (!if_id.valid || id_advance);
  assign imem_req_o = !rst_i && (fetch_pending || issue_fetch);
  assign imem_addr_o = fetch_pending ? pending_pc : fetch_pc;
  assign accept_fetch = imem_req_o && imem_ack_i && !flush_front && !discard_fetch;

  assign pc_o = fetch_pc;
  assign retire_o = mem_wb.valid;
  assign retire_pc_o = mem_wb.pc;
  assign retire_inst_o = mem_wb.inst;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      fetch_pc <= RESET_PC;
      pending_pc <= '0;
      fetch_pending <= 0;
      discard_fetch <= 0;
      illegal_o <= 0;
      if_id <= '0;
    end else begin
      illegal_o <= illegal_trap;
      // Once issued, the fetch owns its IF/ID slot until ACK or a redirect.
      if (issue_fetch) begin
        fetch_pc <= fetch_pc + 4;
        if (!imem_ack_i) begin
          pending_pc <= fetch_pc;
          fetch_pending <= 1;
        end
      end
      if (fetch_pending && imem_ack_i) begin
        fetch_pending <= 0;
        discard_fetch <= 0;
      end

      if (flush_front) begin
        if_id.valid <= 0;
        if (fetch_pending && !imem_ack_i) discard_fetch <= 1;
        fetch_pc <= redirect_pc;
      end else if (accept_fetch) begin
        if_id <= {1'b1, imem_addr_o, imem_rdata_i};
      end else if (id_advance) begin
        if_id.valid <= 0;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      id_ex <= '0;
      ex_mem <= '0;
      mem_wb <= '0;
    end else begin
      // WB is consumed each cycle even when MEM holds a pending request.
      mem_wb.valid <= 0;
      if (mem_can_advance) begin
        mem_wb.valid <= ex_mem.valid;
        mem_wb.pc <= ex_mem.pc;
        mem_wb.inst <= ex_mem.inst;
        mem_wb.rd <= ex_mem.rd;
        mem_wb.result <= ex_mem.load ? load_result : ex_mem.result;
        mem_wb.write_rd <= ex_mem.write_rd;

        ex_mem.valid <= id_ex.valid && !trap;
        ex_mem.pc <= id_ex.pc;
        ex_mem.inst <= id_ex.inst;
        ex_mem.rd <= id_ex.rd;
        ex_mem.result <= csr_access ? csr_value : (link_result ? (id_ex.pc + 4) : alu_result);
        ex_mem.store_data <= ex_rs2;
        ex_mem.write_rd <= id_ex.control.write_rd;
        ex_mem.load <= id_ex.control.load;
        ex_mem.store <= id_ex.control.store;
        ex_mem.byte_access <= id_ex.control.byte_access;

        id_ex.valid <= id_advance;
        if (id_advance) begin
          id_ex.pc <= if_id.pc;
          id_ex.inst <= if_id.inst;
          id_ex.imm <= id_imm;
          id_ex.control <= id_control;
          id_ex.rs1 <= id_rs1;
          id_ex.rs2 <= id_rs2;
          id_ex.rd <= if_id.inst[11:7];
          id_ex.rs1_value <= (wb_write && mem_wb.rd == id_rs1) ? mem_wb.result : rs1_data;
          id_ex.rs2_value <= (wb_write && mem_wb.rd == id_rs2) ? mem_wb.result : rs2_data;
        end
      end else if (id_ex.valid) begin
        // Preserve a forwarding value that would otherwise leave WB during the stall.
        if (wb_write && mem_wb.rd == id_ex.rs1) id_ex.rs1_value <= mem_wb.result;
        if (wb_write && mem_wb.rd == id_ex.rs2) id_ex.rs2_value <= mem_wb.result;
      end
    end
  end
endmodule
