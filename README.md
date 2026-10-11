A simple single cycle RISC-V processor in verilog

# how to run this

1. write your instructions in program.hex, and your preferred test bench in tb_riscv_core.v
2. run `iverilog -o riscv.sim *.v` in the terminal
3. run `vvp riscv.sim` in the terminal
