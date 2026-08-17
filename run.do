quit -sim
vdel -all -lib work
vlib work

transcript file simulation.log

vlog +cover=bcesft -covercells -f files.txt

vsim -voptargs="+acc" -coverage work.AXI_top

add wave -r /*
run -all

coverage save AXI_coverage.ucdb

coverage report -detail -cvg -output functional_coverage.txt

coverage report -detail -code bcesft -output design_code_coverage.txt

coverage report -detail -output full_coverage_report.txt