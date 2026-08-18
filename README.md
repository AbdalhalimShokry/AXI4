# AXI4 Verification Project


## Project overview


This repository contains a SystemVerilog testbench and a simple AXI4 DUT (axi4) with a memory model (axi4_memory). The testbench implements a directed + constrained-random verification flow using class-based transactions, a generator, driver, monitor, scoreboard (golden model), assertions, and functional coverage. Scripts are provided to compile and run the full verification with QuestaSim and to produce coverage and assertion reports.


## AXI4 features supported



- Full write and read channels (AW/AWREADY, W/WREADY/WLAST, B/BVALID/BRESP; AR/ARREADY, R/RVALID/RLAST/RRESP)

- Burst transfers (AWLEN/ARLEN up to 8-bit)

- Beat size fixed to 4 bytes (AWSIZE / ARSIZE constrained to 3'd2)

- Address alignment checks (4-byte aligned transfers)

- 4 KB boundary checks (detection of illegal cross-boundary bursts)

- Slave responses: OKAY (2'b00) and SLVERR (2'b10)

- Internal reference memory of 1024 words (32-bit)



## DUT and testbench architecture



- DUT: axi4 (rtl) backed by axi4_memory (word-addressed memory).

- Top-level TB: AXI_top.sv instantiates AXI_interface and the DUT, attaches AXI_assertions, and creates AXI_environment.

- Environment: AXI_environment (package) composes generator, driver, monitor, and scoreboard and wires mailboxes between them.

- Flow: AXI_generator -> AXI_driver -> DUT -> AXI_monitor -> AXI_scoreboard (and scoreboard compares DUT behavior vs golden model).

- Coverage & Assertions collected during simulation; several coverage reports are generated post-run.



## SystemVerilog components (files)



- axi4.v — DUT: AXI4 slave with write/read FSMs and memory instantiation

- axi4_memory.v — simple synchronous memory used by DUT

- AXI_interface.sv — virtual interface and modport for TB

- AXI_transaction.sv — AXI_transaction class (fields, constraints, display)

- AXI_generator.sv — generator class: directed tests + randomized transactions, mailboxes to driver/scoreboard

- AXI_driver.sv — driver class: drives AW/W/B and AR/R channels, implements backpressure scenarios

- AXI_monitor.sv — monitor class: samples DUT transactions, instantiates covergroup(s)

- AXI_scoreboard.sv — scoreboard: reference memory (golden_model), compares expected vs actual, reports pass/fail counts

- AXI_environment.sv — environment class: constructs and connects components and mailboxes; starts run_env()

- AXI_assertions.sv — SystemVerilog assertions: stability properties and no-X checks

- AXI_top.sv — top-level testbench: clock/reset, DUT instantiation, environment start

- run.do — QuestaSim do-script to compile, run, and collect coverage/reports

- run.bat — Windows wrapper to launch QuestaSim with run.do



## Transactions, generator, driver, monitor, scoreboard, reference model



- Transaction: AXI_transaction class (32-bit data, 16-bit address, MEMORY_DEPTH=1024). Constraints:

- AWSIZE == 3'd2 and ARSIZE == 3'd2 (4-byte beats)

- AWADDR and ARADDR 4-byte aligned

- AWADDR/ARADDR < 4096 bytes

- WDATA array size equals AWLEN + 1

- Generator: AXI_generator runs:

- Directed tests (names in code): DIR_LOWER_BOUND_WR, DIR_LOWER_BOUND_RD, DIR_UPPER_BOUND_WR, DIR_UPPER_BOUND_RD, DIR_4KB_EXACT_WR, DIR_OUT_OF_BOUNDS_WR, DIR_OUT_OF_BOUNDS_RD, DIR_ILLEGAL_CROSS_WR, DIR_WRITE_CHECK, DIR_READ_CHECK

- Then a randomized phase (num_transactions default 10000 -Can be changed using num_transaction variable-, randomized transaction fields subject to constraints)

- Communicates via mailboxes (gen2drv_mbx, gen2scb_mbx) and waits for tokens from driver/scoreboard

- Driver: AXI_driver implements timing/backpressure:

- Drives AW phase then W data (handles WLAST)

- Applies BREADY backpressure for stability testing

- Drives AR phase then toggles RREADY to exercise RVALID stability

- Uses mailboxes to synchronize with generator

- Monitor: AXI_monitor samples address/data/response events and sends sampled AXI_transaction objects to scoreboard via mon2scb_mbx. Also instantiates covergroup cg_axi_protocol (coverpoints for addresses, lengths, boundaries, response transitions, crosses) and samples transactions for coverage.

- Scoreboard: AXI_scoreboard implements golden_model(expected) that updates or checks a reference memory array (1024 x 32-bit) and sets expected BRESP/RRESP values (OKAY or SLVERR) based on alignment, address range, and 4KB boundary crossing. Compares expected vs actual from monitor and prints pass/fail counts. At end prints a scoreboard summary.



## Assertions



- AXI_assertions.sv includes:

- Stability assertions: AWVALID/WVALID/BVALID/ARVALID/RVALID stability properties (if valid && not ready then signals remain stable)

- Known-value (no-X) checks on relevant signals when VALID is asserted

- Both assertions and equivalent cover properties exist in the file

## Coverage



- AXI_monitor contains covergroup cg_axi_protocol with coverpoints for AWADDR, ARADDR, AWLEN, ARLEN, write/read boundary expressions, and response transitions. Cross coverage included with ignore_bins for out-of-range addresses.

- run.do saves coverage database (coverage_report.ucdb) and writes textual reports:

- functional_coverage.txt

- design_code_coverage.txt

- assertion_coverage_report.txt

- full_coverage_report.txt



## Test scenarios



- Directed tests (explicit, see generator):

- Lower/Upper bound writes and reads

- Exact 4KB boundary write case

- Out-of-bounds accesses (addresses >= 0xF000 in directed cases)

- Illegal boundary-crossing write (burst crossing 4KB boundary)

- Data integrity write/read pair (writes known pattern then reads same address)

- Randomized transactions:

- Transactions randomized under constraints (AWSIZE/ARSIZE fixed to 4B, alignment, AW/AR address limits). Generator sends a configurable number (num_transactions) of randomized transactions after directed tests.



## QuestaSim compilation and simulation instructions


Prerequisites: QuestaSim (ModelSim/Questa) installed and vsim/vlog accessible.


Quick run (Windows):



1. Open a command prompt in repo root.

2. Run run.bat:

- run.bat will clean the work folder and call vsim with the run.do script.

- It assumes Questa is installed at: C:\questasim64_2021.1\win64\vsim.exe (edit run.bat if your installation differs).

3. run.do (what it does):

- vlib work

- transcript file simulation.log

- Compile with coverage/assert flags:

vlog +cover=bcesft -covercells -assertdebug 

axi4.v axi_memory.v AXI_interface.sv AXI_transaction.sv AXI_generator.sv AXI_driver.sv AXI_monitor.sv AXI_scoreboard.sv AXI_environment.sv AXI_assertions.sv AXI_top.sv

- Simulate:

vsim -voptargs="+acc" -coverage -cvgperinstance -assertdebug work.AXI_top

run -all

- Save coverage DB:

coverage save coverage_report.ucdb

- Generate reports:

coverage report -detail -cvg -file functional_coverage.txt

coverage report -detail -code bcesft -file design_code_coverage.txt

coverage report -detail -assert -file assertion_coverage_report.txt

coverage report -detail -file full_coverage_report.txt

- Quit

4. Results:

- simulation.log contains transcript

- coverage_report.ucdb contains UCDB coverage database

- Human readable reports: functional_coverage.txt, design_code_coverage.txt, assertion_coverage_report.txt, full_coverage_report.txt

- assertion_coverage_report.txt is produced by run.do



Notes:



- Edit run.bat to point to your QuestaSim executable if different.

- run.bat kills vsim/vlog/vopt/vish processes before/after run to avoid stale processes.

- run.do compiles all SystemVerilog and Verilog sources used by the testbench/DUT.



## Project directory structure


(Top-level files in repository root)



- axi4.v

- axi_memory.v

- AXI_interface.sv

- AXI_transaction.sv

- AXI_generator.sv

- AXI_driver.sv

- AXI_monitor.sv

- AXI_scoreboard.sv

- AXI_environment.sv

- AXI_assertions.sv

- AXI_top.sv

- AXI4_Memory_SV_Project.pdf

- AXI_transaction.sv

- run.do

- run.bat

- run.do (script)

- simulation.log (generated)

- coverage_report.ucdb (generated by run.do)

- functional_coverage.txt (generated)

- design_code_coverage.txt (generated)

- assertion_coverage_report.txt (generated)

- full_coverage_report.txt (generated)

- assertion_coverage_report.txt (generated)



(Actual file list in repo root corresponds to the files above; coverage/report/log outputs are produced by simulation runs.)


## Contributors



- Repository owner: AbdalhalimShokry (repository: AbdalhalimShokry/AXI4)

- For a complete contributor list and commit history, run:

git log --pretty=format:"%an <%ae>" | sort | uniq



## License and citation



- No explicit license file present in the repository root. If this matters, add a LICENSE file.



## Notes and limitations (no invention)



- The testbench constrains AWSIZE/ARSIZE to 3'd2 (4B beats) in the transaction class and generator; the DUT and monitor follow the same assumption.

- Address space checks use 4 KB boundaries and a 1024-word reference memory (32-bit words).

- Do not assume features not present in the source files (for example: no AXI-lite, no ID/LOCK/PROT/USER fields, no concurrency beyond single-channel bursts implemented).
