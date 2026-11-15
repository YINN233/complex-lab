`timescale 1ns / 1ps

module tb_lab5_mem;

  logic clk = 0;
  logic rst = 1;
  logic [15:0] leds;

  wire [31:0] base_ram_data;
  wire [19:0] base_ram_addr;
  wire [3:0] base_ram_be_n;
  wire base_ram_ce_n;
  wire base_ram_oe_n;
  wire base_ram_we_n;

  wire [31:0] ext_ram_data;
  wire [19:0] ext_ram_addr;
  wire [3:0] ext_ram_be_n;
  wire ext_ram_ce_n;
  wire ext_ram_oe_n;
  wire ext_ram_we_n;

  wire txd;
  logic rxd = 1;

  integer errors = 0;

  lab5_soc dut (
      .clk(clk),
      .rst(rst),
      .leds(leds),
      .base_ram_data(base_ram_data),
      .base_ram_addr(base_ram_addr),
      .base_ram_be_n(base_ram_be_n),
      .base_ram_ce_n(base_ram_ce_n),
      .base_ram_oe_n(base_ram_oe_n),
      .base_ram_we_n(base_ram_we_n),
      .ext_ram_data(ext_ram_data),
      .ext_ram_addr(ext_ram_addr),
      .ext_ram_be_n(ext_ram_be_n),
      .ext_ram_ce_n(ext_ram_ce_n),
      .ext_ram_oe_n(ext_ram_oe_n),
      .ext_ram_we_n(ext_ram_we_n),
      .txd(txd),
      .rxd(rxd)
  );

  sram_model_lab5 #(.MODE(2)) u_base (
      .data(base_ram_data),
      .addr(base_ram_addr),
      .ce_n(base_ram_ce_n),
      .oe_n(base_ram_oe_n),
      .we_n(base_ram_we_n),
      .be_n(base_ram_be_n)
  );

  sram_model_lab5 #(.MODE(2)) u_ext (
      .data(ext_ram_data),
      .addr(ext_ram_addr),
      .ce_n(ext_ram_ce_n),
      .oe_n(ext_ram_oe_n),
      .we_n(ext_ram_we_n),
      .be_n(ext_ram_be_n)
  );

  always #50 clk = ~clk;

  initial begin
    #300;
    rst = 0;
  end

  initial begin
    #1_000_000;
    $display("TIMEOUT pc=%08h", dut.u_cpu.pc);
    $finish;
  end

  initial begin
    wait (dut.u_cpu.pc == 32'h8000_0028);
    repeat (10) @(posedge clk);

    if (u_base.mem[32'h40] !== 32'h007F_8000) begin
      $display("FAIL word 0x100=%08h", u_base.mem[32'h40]);
      errors = errors + 1;
    end

    if (u_base.mem[32'h41] !== 32'hFFFF_FF80) begin
      $display("FAIL word 0x104=%08h", u_base.mem[32'h41]);
      errors = errors + 1;
    end

    if (u_base.mem[32'h42] !== 32'h0000_007F) begin
      $display("FAIL word 0x108=%08h", u_base.mem[32'h42]);
      errors = errors + 1;
    end

    if (errors == 0) $display("LAB5 MEM TEST PASSED");
    else $display("LAB5 MEM TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule
