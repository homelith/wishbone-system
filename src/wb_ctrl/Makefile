#-------------------------------------------------------------------------------
# Makefile for iverilog
#
# usage :
#   make build => compile
#   make show  => simulation with GUI
#   make clean => cleanup
#-------------------------------------------------------------------------------
.PHONY : default sim show clean

SRCS = *.v
TOP_MODULE = tb

default : show

sim :
	iverilog -o dump.out -s $(TOP_MODULE) $(SRCS)
	vvp dump.out

show : sim
	twinwave + dump.vcd

clean :
	@rm -rf dump.out dump.vcd
