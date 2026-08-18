# Create fresh library
vlib work

transcript file simulation.log

# Compile design and testbench
vlog +cover=bcesft -covercells \
    axi4.v \
    axi_memory.v \
    AXI_interface.sv \
    AXI_transaction.sv \
    AXI_generator.sv \
    AXI_driver.sv \
    AXI_monitor.sv \
    AXI_scoreboard.sv \
    AXI_environment.sv \
    AXI_assertions.sv \
    AXI_top.sv

# Load simulation
vsim -voptargs="+acc" -coverage -cvgperinstance work.AXI_top

# Run simulation to completion
run -all

# Save database and export reports
coverage save coverage_report.ucdb
coverage report -detail -cvg -file functional_coverage.txt
coverage report -detail -code bcesft -file design_code_coverage.txt
coverage report -detail -file full_coverage_report.txt

quit -f