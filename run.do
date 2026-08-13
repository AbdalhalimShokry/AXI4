vlog axi4.v axi_memory.v AXI_interface.sv AXI_transaction.sv AXI_generator.sv AXI_driver.sv AXI_monitor.sv AXI_scoreboard.sv AXI_encironment.sv AXI_assertions.sv AXI_top.sv +cover -covercells

vsim work.top -cover

coverage save -onexit cov.ucdb

add wave *

run -all

coverage report -details -output cov_report.txt