`timescale 1ns / 1ps

module tb_regfile32;

  logic        clk = 0;
  logic        rst;
  logic        we;
  logic [ 4:0] waddr;
  logic [31:0] wdata;
  logic [ 4:0] raddr_a;
  logic [31:0] rdata_a;
  logic [ 4:0] raddr_b;
  logic [31:0] rdata_b;
  integer      errors = 0;

  regfile32 dut (
      .clk    (clk),
      .rst    (rst),
      .we     (we),
      .waddr  (waddr),
      .wdata  (wdata),
      .raddr_a(raddr_a),
      .rdata_a(rdata_a),
      .raddr_b(raddr_b),
      .rdata_b(rdata_b)
  );

  always #5 clk = ~clk;

  task check;
    input [31:0] exp_a;
    input [31:0] exp_b;
    begin
      #1;
      if ((rdata_a !== exp_a) || (rdata_b !== exp_b)) begin
        $display("FAIL a[%0d]=%08h b[%0d]=%08h exp_a=%08h exp_b=%08h",
                 raddr_a, rdata_a, raddr_b, rdata_b, exp_a, exp_b);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    rst = 1; we = 0; waddr = 0; wdata = 0; raddr_a = 0; raddr_b = 0;
    repeat (3) @(posedge clk);
    rst = 0;
    @(posedge clk);

    we = 1; waddr = 5'd1; wdata = 32'h1234_5678;
    @(posedge clk);
    #1;
    we = 0;
    raddr_a = 5'd1; raddr_b = 5'd0; check(32'h1234_5678, 32'h0);

    we = 1; waddr = 5'd0; wdata = 32'hDEAD_BEEF;
    @(posedge clk);
    #1;
    we = 0;
    raddr_a = 5'd0; raddr_b = 5'd1; check(32'h0, 32'h1234_5678);

    we = 1; waddr = 5'd31; wdata = 32'hA5A5_5A5A;
    @(posedge clk);
    #1;
    we = 0;
    raddr_a = 5'd31; raddr_b = 5'd1; check(32'hA5A5_5A5A, 32'h1234_5678);

    if (errors == 0) $display("REGFILE32 TEST PASSED");
    else $display("REGFILE32 TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule
