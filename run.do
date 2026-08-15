vlog +cover -covercells -f files.txt

vsim -voptargs=+acc work.AXI_top

add wave -r /*
run -all

coverage save AXI_coverage.ucdb
coverage report -details -output AXI_coverage.txt