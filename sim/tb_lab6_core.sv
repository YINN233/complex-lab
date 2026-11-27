`timescale 1ns / 1ps

module tb_lab6_core;
  localparam logic [31:0] BOOT = 32'h8000_0000;
  logic clk = 0;
  logic rst = 1;
  always #5 clk = ~clk;

  wire ireq, dreq, dwe, illegal, retire;
  wire [31:0] iaddr, daddr, dwdata, retire_pc, retire_inst;
  wire [3:0] dsel;
  logic [31:0] memory [0:2047];
  logic [31:0] data [0:3];
  string program_file;
  integer delay_mode, iwait = 0, dwait = 0;
  integer irequests = 0, drequests = 0, writes = 0, hazards = 0, redirects = 0;
  integer dropped_fetches = 0, stalled_forwards = 0;
  logic ioutstanding = 0, doutstanding = 0;
  logic [31:0] old_iaddr, old_daddr, old_dwdata;
  logic [4:0] old_data_control;

  wire iack = ireq && ((delay_mode != 1) ||
                       (ioutstanding && iwait == 0));
  wire dack = dreq && ((delay_mode == 0) ||
                       (doutstanding && dwait == 0));
  wire [31:0] idata = memory[iaddr[12:2]];
  wire [31:0] drdata = data[daddr[3:2]];

  lab6_core dut (
      .clk_i(clk), .rst_i(rst),
      .timer_irq_i(1'b0), .uart_irq_i(1'b0),
      .imem_req_o(ireq), .imem_addr_o(iaddr), .imem_ack_i(iack), .imem_rdata_i(idata),
      .dmem_req_o(dreq), .dmem_addr_o(daddr), .dmem_we_o(dwe),
      .dmem_sel_o(dsel), .dmem_wdata_o(dwdata), .dmem_ack_i(dack), .dmem_rdata_i(drdata),
      .illegal_o(illegal), .pc_o(), .retire_o(retire),
      .retire_pc_o(retire_pc), .retire_inst_o(retire_inst)
  );

  initial begin
    if (!$value$plusargs("PROGRAM=%s", program_file)) $fatal(1, "missing PROGRAM");
    if (!$value$plusargs("DELAY=%d", delay_mode)) delay_mode = 0;
    $readmemh(program_file, memory);
    foreach (data[i]) data[i] = 0;
    repeat (3) @(negedge clk);
    rst = 0;
    repeat (12000) @(negedge clk);
    $fatal(1, "timeout, last retired PC %h, instruction %h", retire_pc, retire_inst);
  end

  always @(posedge clk) if (!rst) begin
    if (illegal) $fatal(1, "unexpected illegal instruction");
    if (dut.load_use && dut.mem_can_advance) hazards <= hazards + 1;
    if (dut.redirect) redirects <= redirects + 1;
    if (dut.redirect && dut.fetch_pending) dropped_fetches <= dropped_fetches + 1;
    if (!dut.mem_can_advance && dut.id_ex.valid && dut.wb_write &&
        dut.mem_wb.rd == dut.id_ex.rs1) stalled_forwards <= stalled_forwards + 1;

    if (ioutstanding && (!ireq || iaddr !== old_iaddr))
      $fatal(1, "instruction request changed before ACK");
    if (doutstanding && (!dreq || daddr !== old_daddr || dwdata !== old_dwdata ||
                         {dwe, dsel} !== old_data_control))
      $fatal(1, "data request changed before ACK");

    if (ireq && !ioutstanding) begin
      if (iaddr < BOOT || iaddr >= BOOT + 8192)
        $fatal(1, "unexpected fetch %h", iaddr);
      old_iaddr <= iaddr;
      iwait <= irequests % 5;
      irequests <= irequests + 1;
    end else if (ioutstanding && iwait != 0) iwait <= iwait - 1;
    ioutstanding <= ireq && !iack;

    if (dreq && !doutstanding) begin
      if (daddr < BOOT + 4096 || daddr >= BOOT + 4112)
        $fatal(1, "unexpected data address %h", daddr);
      old_daddr <= daddr;
      old_dwdata <= dwdata;
      old_data_control <= {dwe, dsel};
      dwait <= 1 + (drequests % 7);
      drequests <= drequests + 1;
    end else if (doutstanding && dwait != 0) dwait <= dwait - 1;
    doutstanding <= dreq && !dack;

    if (dack && dwe) begin
      if (daddr[3:0] == 12) $fatal(1, "wrong-path store");
      if (daddr[3:0] == 5 && (dsel !== 4'b0010 || dwdata[15:8] !== 8'h80))
        $fatal(1, "incorrect byte lane");
      for (int lane = 0; lane < 4; lane++)
        if (dsel[lane]) data[daddr[3:2]][8*lane +: 8] <= dwdata[8*lane +: 8];
      writes <= writes + 1;
      if (daddr[3:0] == 8) begin
        if (dwdata !== 32'h123 || data[0] !== 31 || data[1] !== 32'h8022)
          $fatal(1, "program failed at %h (signature %h)", retire_pc, dwdata);
        if (writes != 3 || redirects == 0 ||
            (delay_mode != 1 && hazards == 0) ||
            (delay_mode == 1 && dropped_fetches == 0) ||
            (delay_mode == 2 && stalled_forwards == 0))
          $fatal(1, "missing coverage or repeated write");
        $display("LAB6 CORE PASS delay=%0d load-use=%0d redirects=%0d discarded-fetches=%0d held-WB=%0d",
                 delay_mode, hazards, redirects, dropped_fetches, stalled_forwards);
        $finish;
      end
    end
  end
endmodule
