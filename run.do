onbreak resume
coverage save -onexit uvm_fifo.ucdb
run 0
run -all
coverage report -details
quit -f
