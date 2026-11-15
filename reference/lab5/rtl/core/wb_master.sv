`timescale 1ns / 1ps

`default_nettype none

module wb_master (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        req_valid_i,
    input  wire        req_we_i,
    input  wire [31:0] req_addr_i,
    input  wire [31:0] req_wdata_i,
    input  wire [ 3:0] req_sel_i,
    output logic        resp_valid_o,
    output logic [31:0] resp_rdata_o,

    output logic        wb_cyc_o,
    output logic        wb_stb_o,
    output logic [31:0] wb_adr_o,
    output logic [31:0] wb_dat_o,
    output logic [ 3:0] wb_sel_o,
    output logic        wb_we_o,
    input  wire        wb_ack_i,
    input  wire [31:0] wb_dat_i
);

  typedef enum logic [1:0] {
    ST_IDLE,
    ST_REQ,
    ST_DONE
  } state_t;

  state_t state = ST_IDLE;

  logic [31:0] addr_reg;
  logic [31:0] wdata_reg;
  logic [ 3:0] sel_reg;
  logic        we_reg;
  logic [31:0] rdata_reg;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      state        <= ST_IDLE;
      addr_reg     <= 32'b0;
      wdata_reg    <= 32'b0;
      sel_reg      <= 4'b0;
      we_reg       <= 1'b0;
      rdata_reg    <= 32'b0;
      resp_valid_o <= 1'b0;
    end else begin
      case (state)
        ST_IDLE: begin
          if (req_valid_i) begin
            addr_reg  <= req_addr_i;
            wdata_reg <= req_wdata_i;
            sel_reg   <= req_sel_i;
            we_reg    <= req_we_i;
            state     <= ST_REQ;
          end
        end

        ST_REQ: begin
          if (wb_ack_i) begin
            rdata_reg    <= wb_dat_i;
            resp_valid_o <= 1'b1;
            state        <= ST_DONE;
          end
        end

        ST_DONE: begin
          resp_valid_o <= 1'b0;
          state        <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

  assign wb_cyc_o     = (state == ST_REQ);
  assign wb_stb_o     = (state == ST_REQ) && !wb_ack_i;
  assign wb_adr_o     = addr_reg;
  assign wb_dat_o     = wdata_reg;
  assign wb_sel_o     = sel_reg;
  assign wb_we_o      = we_reg;
  assign resp_rdata_o = rdata_reg;

endmodule

`default_nettype wire
