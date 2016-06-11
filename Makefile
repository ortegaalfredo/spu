
VERILOG=iverilog
VERILOG8=../icarus8/bin/iverilog

all: seccpu.vvp
seccpu.vvp: blockram.v seccpu.v seccpu.inc seccpu_tb.v

clean:
	$(RM) *.vpp *.vcd 

# Create an Icarus processed file from a verilog source
%.vvp: %.v
	$(VERILOG) -o $@ $^

