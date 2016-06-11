/* CPU Testbench */

`define SECCPU


`ifndef TEST_FILE
`define TEST_FILE "blockram.dat"
`endif


`ifndef TEST_CYCLES
`define TEST_CYCLES 1000
`endif

`include "seccpu.inc"


module seccpu_tb;


parameter tck = 10, program_cycles = `TEST_CYCLES;


reg clk, rst, irq; // clock, reset, interrupt request
wire [`code_depth-1:0] paddr; // program instruction address
wire [`data_width-1:0] pdin; // program data input

wire [`data_width-1:0] dout; // data out
wire [`data_depth-1:0] daddr; // data address

reg [`data_width-1:0] data[0:`data_size-1]; // port memory

wire [`data_width-1:0] din = data[daddr]; // port input


/* Program memory */
blockram #(.width(`code_width), .depth(`code_depth))
	rom(
	.clk(clk),
	.rst(rst),
	.enb(1'b1),
	.wen(1'b0),
	.addr(paddr),
	.din(`code_width 'b0),
	.dout(pdin)
);


/* SecCPU implementation */
seccpu cpu(
	.clk(clk),
	.reset(rst),
	.address(paddr),
	.instruction(pdin),
	.data_address(daddr),
	.read_strobe(ren),
	.write_strobe(wen),
	.data_in(din),
	.data_out(dout),
	.intr(irq)
);

/* Data memory assignment*/
always @(posedge clk)	if (wen) data[daddr] <= dout;

/* Clocking device */
always #(tck/2) 
	clk = ~clk;

integer clkcount=0;
always @ (posedge clk)
	begin
	clkcount=clkcount+1;
	$display ("--- clk %d ---",clkcount);
	end
/* Simulation setup */
initial begin
	$dumpfile("seccpu_tb.vcd");
	$readmemh(`TEST_FILE, rom.ram);
	`ifdef SECURITY_
	$display ("CPU has security extensions activated.");
	`endif
end



/* Simulation */
integer i;
initial begin
	for (i=0; i<`data_size; i=i+1) data[i] = 8'h42; // initialize data
	clk = 0; rst = 1; irq = 0;
	//#(tck*2);
	@(negedge clk) rst = 0; // free processor
	$display ("Start...");
	#(program_cycles*tck+100) 
	$display ("Finish.");
	$finish;
end


endmodule
