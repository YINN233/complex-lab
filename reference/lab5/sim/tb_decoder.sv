`timescale 1ns / 1ps

module tb_decoder;

  logic [31:0] inst;
  logic        reg_we;
  logic        mem_read;
  logic        mem_write;
  logic [ 2:0] alu_op;
  logic        alu_b_sel;
  logic        wb_src;
  logic        branch;
  logic        mem_size;
  logic [ 2:0] imm_type;
  logic [ 4:0] rs1;
  logic [ 4:0] rs2;
  logic [ 4:0] rd;
  integer      errors = 0;

  decoder dut (
      .inst     (inst),
      .reg_we   (reg_we),
      .mem_read (mem_read),
      .mem_write(mem_write),
      .alu_op   (alu_op),
      .alu_b_sel(alu_b_sel),
      .wb_src   (wb_src),
      .branch   (branch),
      .mem_size (mem_size),
      .imm_type (imm_type),
      .rs1      (rs1),
      .rs2      (rs2),
      .rd       (rd)
  );

  task check;
    input        exp_reg_we;
    input        exp_mem_read;
    input        exp_mem_write;
    input [ 2:0] exp_alu_op;
    input        exp_alu_b_sel;
    input        exp_wb_src;
    input        exp_branch;
    input        exp_mem_size;
    input [ 2:0] exp_imm_type;
    begin
      #1;
      if (reg_we !== exp_reg_we || mem_read !== exp_mem_read || mem_write !== exp_mem_write ||
          alu_op !== exp_alu_op || alu_b_sel !== exp_alu_b_sel || wb_src !== exp_wb_src ||
          branch !== exp_branch || mem_size !== exp_mem_size || imm_type !== exp_imm_type) begin
        $display("FAIL inst=%08h reg_we=%0b mem_r=%0b mem_w=%0b alu_op=%0d alu_b=%0b wb_src=%0b br=%0b size=%0b imm_type=%0d",
                 inst, reg_we, mem_read, mem_write, alu_op, alu_b_sel, wb_src, branch, mem_size, imm_type);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    inst = 32'h800002b7; check(1, 0, 0, 3'd5, 1, 0, 0, 0, 3'd3);
    inst = 32'h00128293; check(1, 0, 0, 3'd0, 1, 0, 0, 0, 3'd0);
    inst = 32'h02037313; check(1, 0, 0, 3'd2, 1, 0, 0, 0, 3'd0);
    inst = 32'h007283b3; check(1, 0, 0, 3'd0, 0, 0, 0, 0, 3'd4);
    inst = 32'h00528303; check(1, 1, 0, 3'd0, 1, 1, 0, 0, 3'd0);
    inst = 32'h00a28023; check(0, 0, 1, 3'd0, 1, 0, 0, 0, 3'd1);
    inst = 32'h1072a023; check(0, 0, 1, 3'd0, 1, 0, 0, 1, 3'd1);
    inst = 32'h00628463; check(0, 0, 0, 3'd1, 0, 0, 1, 0, 3'd2);
    inst = 32'h00000000; check(0, 0, 0, 3'd0, 0, 0, 0, 0, 3'd4);

    if (errors == 0) $display("DECODER TEST PASSED");
    else $display("DECODER TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule
