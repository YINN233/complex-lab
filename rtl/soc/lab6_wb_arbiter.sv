`timescale 1ns / 1ps

module lab6_wb_arbiter (
    input  logic        clk_i, rst_i,
    input  logic        if_cyc_i, if_stb_i,
    input  logic [31:0] if_addr_i,
    output logic        if_ack_o,
    output logic [31:0] if_rdata_o,
    input  logic        mem_cyc_i, mem_stb_i, mem_we_i,
    input  logic [31:0] mem_addr_i, mem_wdata_i,
    input  logic [3:0]  mem_sel_i,
    output logic        mem_ack_o,
    output logic [31:0] mem_rdata_o,
    output logic        bus_cyc_o, bus_stb_o, bus_we_o,
    output logic [31:0] bus_addr_o, bus_wdata_o,
    output logic [3:0]  bus_sel_o,
    input  logic        bus_ack_i,
    input  logic [31:0] bus_rdata_i
);
  typedef enum logic [1:0] {IDLE, FETCH, DATA} owner_t;
  owner_t owner, selected;

  always_comb begin
    selected = owner;
    if (owner == IDLE) begin
      if (mem_cyc_i) selected = DATA;
      else if (if_cyc_i) selected = FETCH;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i || !bus_cyc_o || bus_ack_i) owner <= IDLE;
    else owner <= selected;
  end

  assign bus_cyc_o = !rst_i && ((selected == DATA && mem_cyc_i) ||
                               (selected == FETCH && if_cyc_i));
  assign bus_stb_o = bus_cyc_o && ((selected == DATA) ? mem_stb_i : if_stb_i);
  assign bus_we_o = (selected == DATA) && mem_we_i;
  assign bus_addr_o = (selected == DATA) ? mem_addr_i : if_addr_i;
  assign bus_wdata_o = (selected == DATA) ? mem_wdata_i : 32'b0;
  assign bus_sel_o = (selected == DATA) ? mem_sel_i : 4'b1111;
  assign mem_ack_o = bus_cyc_o && (selected == DATA) && bus_ack_i;
  assign if_ack_o = bus_cyc_o && (selected == FETCH) && bus_ack_i;
  assign mem_rdata_o = bus_rdata_i;
  assign if_rdata_o = bus_rdata_i;
endmodule
