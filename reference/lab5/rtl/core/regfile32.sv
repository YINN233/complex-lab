`timescale 1ns / 1ps

`default_nettype none

module regfile32 (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [ 4:0] waddr,
    input  wire [31:0] wdata,
    input  wire [ 4:0] raddr_a,
    output logic [31:0] rdata_a,
    input  wire [ 4:0] raddr_b,
    output logic [31:0] rdata_b
);

  logic [31:0] regs [0:31];
  integer i;

  always_ff @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < 32; i = i + 1) regs[i] <= 32'b0;
    end else if (we && (waddr != 5'd0)) begin
      regs[waddr] <= wdata;
    end
  end

  always_comb begin
    rdata_a = (raddr_a == 5'd0) ? 32'b0 : regs[raddr_a];
    rdata_b = (raddr_b == 5'd0) ? 32'b0 : regs[raddr_b];
  end

endmodule

`default_nettype wire
