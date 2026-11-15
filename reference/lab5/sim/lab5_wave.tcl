# Source this file in the Vivado Tcl console after opening lab5_cpu_wave_tb.
restart
run 1000ns
catch {remove_wave [get_waves *]}

add_wave_group "Clock and Reset"
add_wave {{/lab5_cpu_wave_tb/clk}}
add_wave {{/lab5_cpu_wave_tb/rst}}

add_wave_group "CPU Control"
add_wave {{/lab5_cpu_wave_tb/u_cpu/state}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/pc}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/pc_now}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/inst}}
add_wave {{/lab5_cpu_wave_tb/u_cpu/zero}}
add_wave {{/lab5_cpu_wave_tb/u_cpu/branch}}
add_wave {{/lab5_cpu_wave_tb/u_cpu/mem_read}}
add_wave {{/lab5_cpu_wave_tb/u_cpu/mem_write}}
add_wave {{/lab5_cpu_wave_tb/u_cpu/reg_we}}

add_wave_group "Datapath"
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/operand1}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/operand2}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/imm}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/alu_y}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/addr}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/wb_data}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/u_regfile/regs[5]}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/u_regfile/regs[6]}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/u_regfile/regs[7]}}
add_wave -radix hex {{/lab5_cpu_wave_tb/u_cpu/u_regfile/regs[10]}}

add_wave_group "Wishbone"
add_wave {{/lab5_cpu_wave_tb/cpu_wb_cyc}}
add_wave {{/lab5_cpu_wave_tb/cpu_wb_stb}}
add_wave {{/lab5_cpu_wave_tb/cpu_wb_ack}}
add_wave -radix hex {{/lab5_cpu_wave_tb/cpu_wb_adr}}
add_wave -radix hex {{/lab5_cpu_wave_tb/cpu_wb_dat_o}}
add_wave -radix hex {{/lab5_cpu_wave_tb/cpu_wb_dat_i}}
add_wave {{/lab5_cpu_wave_tb/cpu_wb_sel}}
add_wave {{/lab5_cpu_wave_tb/cpu_wb_we}}

add_wave_group "SRAM"
add_wave {{/lab5_cpu_wave_tb/wbs0_cyc}}
add_wave {{/lab5_cpu_wave_tb/wbs0_stb}}
add_wave {{/lab5_cpu_wave_tb/wbs0_ack}}
add_wave -radix hex {{/lab5_cpu_wave_tb/wbs0_adr}}
add_wave -radix hex {{/lab5_cpu_wave_tb/wbs0_dat_o}}
add_wave -radix hex {{/lab5_cpu_wave_tb/wbs0_dat_i}}
add_wave {{/lab5_cpu_wave_tb/wbs0_sel}}
add_wave {{/lab5_cpu_wave_tb/wbs0_we}}
add_wave -radix hex {{/lab5_cpu_wave_tb/sram_addr}}
add_wave -radix hex {{/lab5_cpu_wave_tb/sram_data}}
add_wave {{/lab5_cpu_wave_tb/sram_ce_n}}
add_wave {{/lab5_cpu_wave_tb/sram_oe_n}}
add_wave {{/lab5_cpu_wave_tb/sram_we_n}}
add_wave {{/lab5_cpu_wave_tb/sram_be_n}}

add_wave_group "UART"
add_wave -radix hex {{/lab5_cpu_wave_tb/wbs2_adr}}
add_wave -radix hex {{/lab5_cpu_wave_tb/wbs2_dat_o}}
add_wave {{/lab5_cpu_wave_tb/wbs2_sel}}
add_wave {{/lab5_cpu_wave_tb/wbs2_stb}}
add_wave {{/lab5_cpu_wave_tb/wbs2_ack}}
add_wave {{/lab5_cpu_wave_tb/uart_valid}}
add_wave -radix hex {{/lab5_cpu_wave_tb/uart_data}}
