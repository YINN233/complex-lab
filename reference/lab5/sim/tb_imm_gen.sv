`timescale 1ns / 1ps

module tb_imm_gen;

  logic [31:0] inst;
  logic [ 2:0] imm_type;
  logic [31:0] imm;
  integer      errors = 0;

  imm_gen dut (
      .inst    (inst),
      .imm_type(imm_type),
      .imm     (imm)
  );

  task check;
    input [31:0] exp;
    begin
      #1;
      if (imm !== exp) begin
        $display("FAIL type=%0d inst=%08h imm=%08h exp=%08h", imm_type, inst, imm, exp);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    inst = 32'h00128293; imm_type = 3'd0; check(32'd1);
    inst = 32'hfff28293; imm_type = 3'd0; check(32'hffff_ffff);
    inst = 32'h1072a023; imm_type = 3'd1; check(32'h0000_0100);
    inst = 32'h00628463; imm_type = 3'd2; check(32'd8);
    inst = 32'hfe000ae3; imm_type = 3'd2; check(32'hffff_fff4);
    inst = 32'h800002b7; imm_type = 3'd3; check(32'h8000_0000);
    inst = 32'h007283b3; imm_type = 3'd4; check(32'h0000_0000);

    if (errors == 0) $display("IMM_GEN TEST PASSED");
    else $display("IMM_GEN TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule
