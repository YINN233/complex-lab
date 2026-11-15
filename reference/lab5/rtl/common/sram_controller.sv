`timescale 1ns / 1ps

module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8
) (
    input wire clk_i,
    input wire rst_i,

    input wire wb_cyc_i,
    input wire wb_stb_i,
    output logic wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output logic [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    output logic [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output logic sram_ce_n,
    output logic sram_oe_n,
    output logic sram_we_n,
    output logic [SRAM_BYTES-1:0] sram_be_n
);

  typedef enum logic [2:0] {
    STATE_IDLE,
    STATE_READ,
    STATE_READ_2,
    STATE_WRITE,
    STATE_WRITE_2,
    STATE_WRITE_3,
    STATE_DONE
  } state_t;

  state_t state = STATE_IDLE;
  logic [SRAM_ADDR_WIDTH-1:0] addr_reg;
  logic [SRAM_DATA_WIDTH-1:0] data_reg;
  logic [SRAM_BYTES-1:0] be_reg;
  logic [SRAM_DATA_WIDTH-1:0] rdata_reg;
  logic [SRAM_DATA_WIDTH-1:0] sram_data_o;
  logic sram_data_t;
  wire [SRAM_DATA_WIDTH-1:0] sram_data_i;

  assign sram_data = sram_data_t ? {SRAM_DATA_WIDTH{1'bz}} : sram_data_o;
  assign sram_data_i = sram_data;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      state <= STATE_IDLE;
      addr_reg <= '0;
      data_reg <= '0;
      be_reg <= '0;
      rdata_reg <= '0;
    end else begin
      case (state)
        STATE_IDLE: begin
          if (wb_cyc_i && wb_stb_i) begin
            addr_reg <= wb_adr_i[SRAM_ADDR_WIDTH+1:2];
            be_reg <= ~wb_sel_i;
            if (wb_we_i) begin
              data_reg <= wb_dat_i;
              state <= STATE_WRITE;
            end else begin
              state <= STATE_READ;
            end
          end
        end

        STATE_READ: state <= STATE_READ_2;

        STATE_READ_2: begin
          rdata_reg <= sram_data_i;
          state <= STATE_DONE;
        end

        STATE_WRITE: state <= STATE_WRITE_2;
        STATE_WRITE_2: state <= STATE_WRITE_3;
        STATE_WRITE_3: state <= STATE_DONE;
        STATE_DONE: state <= STATE_IDLE;
        default: state <= STATE_IDLE;
      endcase
    end
  end

  always_comb begin
    wb_ack_o = (state == STATE_DONE);
    wb_dat_o = rdata_reg;
    sram_addr = addr_reg;
    sram_ce_n = 1'b1;
    sram_oe_n = 1'b1;
    sram_we_n = 1'b1;
    sram_be_n = '0;
    sram_data_o = data_reg;
    sram_data_t = 1'b1;

    case (state)
      STATE_READ, STATE_READ_2: begin
        sram_ce_n = 1'b0;
        sram_oe_n = 1'b0;
        sram_we_n = 1'b1;
        sram_be_n = '0;
      end

      STATE_WRITE, STATE_WRITE_2, STATE_WRITE_3: begin
        sram_ce_n = 1'b0;
        sram_oe_n = 1'b1;
        sram_we_n = (state == STATE_WRITE_2) ? 1'b0 : 1'b1;
        sram_be_n = be_reg;
        sram_data_t = 1'b0;
      end

      default: ;
    endcase
  end

endmodule
