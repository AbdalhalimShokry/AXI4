vlib work

transcript file simulation.log

# 1. Compile with full coverage and assertion flags enabled
vlog +cover=bcesft -covercells -assertdebug \
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

# 2. Simulate with full coverage and assertion tracking
vsim -voptargs="+acc" -coverage -cvgperinstance -assertdebug work.AXI_top

# 3. Run all transactions
run -all

# 4. Save coverage database
coverage save coverage_report.ucdb

# 5. Generate all coverage and assertion reports
coverage report -detail -cvg -file functional_coverage.txt
coverage report -detail -code bcesft -file design_code_coverage.txt
coverage report -detail -assert -file assertion_coverage_report.txt
coverage report -detail -file full_coverage_report.txt

quit -f