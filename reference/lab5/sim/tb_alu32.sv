`timescale 1ns / 1ps

module tb_alu32;

  logic [31:0] a;
  logic [31:0] b;
  logic [ 2:0] op;
  logic [31:0] y;
  logic        zero;
  integer      errors = 0;

  alu32 dut (
      .a   (a),
      .b   (b),
      .op  (op),
      .y   (y),
      .zero(zero)
  );

  task check;
    input [31:0] exp_y;
    input        exp_zero;
    begin
      #1;
      if ((y !== exp_y) || (zero !== exp_zero)) begin
        $display("FAIL op=%0d a=%08h b=%08h y=%08h zero=%0b exp_y=%08h exp_zero=%0b",
                 op, a, b, y, zero, exp_y, exp_zero);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    a = 32'd1; b = 32'd2; op = 3'd0; check(32'd3, 1'b0);
    a = 32'd5; b = 32'd3; op = 3'd1; check(32'd2, 1'b0);
    a = 32'd5; b = 32'd5; op = 3'd1; check(32'd0, 1'b1);
    a = 32'hF0F0_00FF; b = 32'h0FF0_0F0F; op = 3'd2; check(32'h00F0_000F, 1'b0);
    a = 32'h1234_5678; b = 32'hFFFF_0000; op = 3'd5; check(32'hFFFF_0000, 1'b0);
    a = 32'hFFFF_FFFF; b = 32'h0000_0001; op = 3'd0; check(32'h0000_0000, 1'b1);
    a = 32'h0; b = 32'h0; op = 3'd1; check(32'h0, 1'b1);

    if (errors == 0) $display("ALU32 TEST PASSED");
    else $display("ALU32 TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule
