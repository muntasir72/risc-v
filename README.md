# RISC-V Single-Cycle Processor Core

A simple, single-cycle RISC-V processor core written in Verilog. This project implements a subset of the 32-bit Base Integer Instruction Set (RV32I), supporting arithmetic, memory operations, and control flow instructions.

## Features

* **Architecture:** 32-bit RISC-V (RV32I)
* **Design:** Single-cycle execution path
* **Supported Instructions:**
* **R-Type & I-Type:** `add`, `sub`, `and`, `or`, `xor`, `sll`, `slt`, `sltu`, `srl`, `sra` (and immediate variants)
* **Memory:** `lw`, `lh`, `lhu`, `lb`, `lbu`, `sw`, `sh`, `sb`
* **Branching & Jumps:** `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`, `jal`, `jalr`
* **Upper Immediates:** `lui`, `auipc`



## File Structure

* `riscv_core.v`: The top-level wrapper that wires the pipeline stages together.
* `alu.v`: Arithmetic Logic Unit for math and logical operations.
* `control_unit.v`: Main decoder that generates control signals based on opcodes and funct fields.
* `regfile.v`: 32x32-bit integer register file (`x0` to `x31`).
* `imem.v`: Instruction memory (ROM) that reads machine code from `program.hex`.
* `dmem.v`: Data memory (RAM) for load and store operations.
* `immgen.v`: Extracts and sign-extends immediate values from instructions.
* `branch_comp.v`: Evaluates branch conditions.
* `pc_reg.v`: Program Counter register.
* `tb_riscv_core.v`: Simple testbench to simulate and verify execution.

## How to Run

1. **Prerequisites:** You need a Verilog simulator like [Icarus Verilog](https://steveicarus.github.io/iverilog/) and a waveform viewer like [GTKWave](https://gtkwave.sourceforge.net/).
2. **Write a Program:** Compile your RISC-V assembly into 32-bit hex machine code. Save it in the root directory as a file named `program.hex` (one instruction per line).
3. **Compile the Verilog Files:**
```bash
iverilog -o riscv_sim *.v

```


4. **Run the Simulation:**
```bash
vvp riscv_sim

```


5. **View Waveforms:** The simulation will output a `.vcd` file. Open it with GTKWave to inspect the clock cycles, PC increments, and register updates:
```bash
gtkwave riscv_core.vcd

```