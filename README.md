A simple single cycle RISC-V processor in verilog

# how to run this

1. write your instructions in program.hex
2. run `iverilog -o sim.vvp riscv_rtype_core_tb.v riscv_rtype_core.v alu.v control_unit.v imem.v pc_reg.v regfile.v` in the terminal
3. you can modify the riscv_rtype_core_tb.v to give the registers initial data
