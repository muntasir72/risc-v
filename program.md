1. **`lui x1, 1`** *(U-Type)*
Loads the Upper Immediate `1` into `x1`. (Sets `x1 = 0x00001000`).
2. **`auipc x2, 0`** *(U-Type)*
Adds an Upper Immediate of `0` to the current Program Counter (which is 4 at this step). (Sets `x2 = 4`).
3. **`addi x3, x0, 15`** *(I-Type - ALU)*
Adds 15 to 0. (Sets `x3 = 15`).
4. **`sub x4, x3, x2`** *(R-Type)*
Subtracts `x2` from `x3` (15 - 4). (Sets `x4 = 11`).
5. **`sw x4, 4(x0)`** *(S-Type)*
Stores the value `11` into Data Memory at address `4`.
6. **`lw x5, 4(x0)`** *(I-Type - Load)*
Loads the value from Data Memory address `4` back out into `x5`. (Sets `x5 = 11`).
7. **`beq x4, x5, 8`** *(B-Type)*
Checks if `x4 == x5` (11 == 11). Since they match, it branches over the next instruction (+8 bytes).
8. **`add x0, x0, x0`** *(NOP)*
This instruction is skipped because of the branch above.
9. **`jal x6, 8`** *(J-Type)*
Jumps over the next instruction (+8 bytes) and links/saves the return address (`PC + 4`, which is `0x24`) into `x6`.
10. **`add x0, x0, x0`** *(NOP)*
This instruction is safely skipped because of the jump above.
11. **`jalr x0, x6, 8`** *(I-Type - Jump)*
Takes the address saved in `x6` (`0x24`), adds an offset of `8`, and jumps to that exact address (`0x2C`).
12. **`jal x0, 0`** *(J-Type / Infinite Loop)*
Located exactly at `0x2C`, this catches the jump from step 11 and loops forever to cleanly stop the program.