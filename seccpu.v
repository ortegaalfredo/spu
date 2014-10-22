/* Main CPU implementation */


/*

Security measures:
	. Range-checking registers
	. Landing instruction
	. Harvard architecture
	. Non-accesible call stack
	. Instruction invalidation
                      
*/


`include "seccpu.inc"

module seccpu(clk,reset,address,instruction,data_address,read_strobe,write_strobe,data_in,data_out,intr);

input clk; //Clock
input reset; //Reset
input intr; //interrupt request
output [`code_depth-1:0] address; // Address bus
input [`code_width-1:0] instruction; //Instruction bus

output [`data_depth-1:0] data_address; //Port (memory) address bus
output [`data_width-1:0] data_out; // Port (memory) data bus

output write_strobe; // port output strobe
output read_strobe; // port input strobe
input [`data_width-1:0] data_in; // Port (memory) data bus (input)


/* Output registers */
reg write_strobe, read_strobe;


// Address latch
reg [`code_depth-1:0] address_latch;
assign address = address_latch;
reg [`data_depth-1:0] data_address_latch;
assign data_address = data_address_latch;

// Data out latch
reg [`data_width-1:0] data_out_latch;
assign data_out = data_out_latch;

// Address latch
/*reg [`code_width-1:0] instruction_latch;
always @ (posedge clk)
	instruction_latch=instruction;
*/

// Registers
reg [`operand_width-1:0] r[0:8];

// Special Registers
reg [`operand_width-1:0] sr[0:3];
`define call_stack_pointer 	sr[0]
`define int_pointer 		sr[1]
`define int_cause 		sr[2]
`define flags			sr[3]

`ifdef SECURITY_
// Range check registers
reg [`operand_width-1:0] rmin[0:8];
reg [`operand_width-1:0] rmax[0:8];
// Call check flag
reg land_flag;
`endif


// Program counter
reg [`operand_width-1:0] pc;
`define program_counter pc

// Hardware call stack
reg [`code_depth-1:0] call_stack[0:`call_stack_max];

// flags
`define ZFLAG  `flags[0:0] // zero
`define SFLAG  `flags[1:1] // sign
`define GFLAG  `flags[2:2] // greater-than (?)
`define RANGE_ON `flags[3:3] // greater-than (?)

// Interrupt code
task do_interrupt;
input [15:0] cause;
begin
	$display("INT Cause %08x",cause);
	call_stack[`call_stack_pointer]=`program_counter;
	`call_stack_pointer=`call_stack_pointer+1;
	`program_counter=`int_pointer;
	`int_cause=cause;
end
endtask


integer i;
// Main loop
always @ (posedge clk or posedge reset)
	begin
	write_strobe=0;
	read_strobe=0;
	address_latch= `program_counter;
	//@ (negedge clk)
	// reset
	if (reset) 
		begin
		`program_counter =  `reset_vector; // load reset vector
		address_latch= `program_counter;
		for (i=0; i<8;i = i+1) // clear registers and special registers
			begin
			r[i] = 0;
			sr[i] = 0;
			`ifdef SECURITY_
				rmin[i]<=0;
				rmax[i]<=0;
			`endif
			end
		land_flag=0;
		$display("Reset");
		end
	else begin
	`program_counter=`program_counter+1;
	if (`program_counter==10)
		`program_counter=0;
	// CALL land test
	`ifdef SECURITY_
	if (land_flag==1)
		if (instruction[5:0]!=`OP_LAND)
			do_interrupt(`INT_INVALID_CALL);
	`endif

	// fetch instruction
	$display("Instruction fetched: %08x:%08x",address_latch,instruction);
	case (instruction[5:0]) // 64 opcodes max
		`OP_NOP: begin
			 end
		`OP_MOV_RR:	begin
				$display("OP_MOV_RR R%02x<=R%02x",instruction[11:9],instruction[8:6]);
				r[instruction[11:9]]=r[instruction[8:6]];
			 	end
		`OP_MOV_RI:	begin
				$display("OP_MOV_RI R%02x<=%04x",instruction[8:6],instruction[17:9]);
				r[instruction[8:6]]=instruction[17:9];
			 	end
		`OP_MOV_RM:	begin
				$display("OP_MOV_RM R%02x<=[%02x]",instruction[8:6],instruction[17:9]);
				data_address_latch=instruction[17:9];
				read_strobe=1;
				//@ (posedge clk) // maybe needed for blockram
				r[instruction[8:6]]=data_in;
			 	end
		`OP_MOV_MR:	begin
				$display("OP_MOV_MR [%02x]<=R%02x",instruction[17:9],instruction[8:6]);
				data_address_latch<=instruction[17:9];
				data_out_latch<=r[instruction[8:6]];
				write_strobe<=1;
			 	end
		`OP_MOV_RS:	begin
				$display("OP_MOV_RS SR%02x<=R%02x",instruction[11:9],instruction[8:6]);
				sr[instruction[11:9]]=r[instruction[8:6]];
			 	end
		`OP_MOV_SR:	begin
				$display("OP_MOV_RS R%02x<=SR%02x",instruction[11:9],instruction[8:6]);
				r[instruction[11:9]]=sr[instruction[8:6]];
				end

		`OP_ADD_RR:	begin
				$display("OP_ADD_RR R%02x+=R%02x",instruction[11:9],instruction[8:6]);
				r[instruction[11:9]]=r[instruction[11:9]] + r[instruction[8:6]];
				end
		`OP_ADD_RI:	begin
				$display("OP_ADD_RI R%02x+=%04x",instruction[8:6],instruction[17:9]);
				r[instruction[8:6]]=r[instruction[8:6]] + instruction[17:9];
				end
		`OP_ADD_RM:	begin
				$display("OP_ADD_RM R%02x+=[%02x]",instruction[8:6],instruction[17:9]);
				data_address_latch=instruction[17:9];
				read_strobe=1;
				r[instruction[8:6]]=r[instruction[8:6]] + data_in;
				end
		`OP_SUB_RR:	begin
				$display("OP_SUB_RR R%02x-=R%02x",instruction[11:9],instruction[8:6]);
				r[instruction[11:9]]=r[instruction[11:9]] - r[instruction[8:6]];
				end
		`OP_SUB_RI:	begin
				$display("OP_SUB_RI R%02x-=%04x",instruction[8:6],instruction[17:9]);
				r[instruction[8:6]]=r[instruction[8:6]] - instruction[17:9];
				end
		`OP_SUB_RM:	begin
				$display("OP_SUB_RM R%02x-=[%02x]",instruction[8:6],instruction[17:9]);
				data_address_latch=instruction[17:9];
				read_strobe=1;
				r[instruction[8:6]]=r[instruction[8:6]] - data_in;
				end
		`OP_AND_RR:	begin
				$display("OP_AND_RR R%02x&=R%02x",instruction[11:9],instruction[8:6]);
				r[instruction[11:9]]=r[instruction[11:9]] & r[instruction[8:6]];
				end
		`OP_AND_RI:	begin
				$display("OP_AND_RI R%02x&=%04x",instruction[8:6],instruction[17:9]);
				r[instruction[8:6]]=r[instruction[8:6]] & instruction[17:9];
				end
		`OP_OR_RR:	begin
				$display("OP_OR_RR R%02x|=R%02x",instruction[11:9],instruction[8:6]);
				r[instruction[11:9]]=r[instruction[11:9]] | r[instruction[8:6]];
				end
		`OP_OR_RI:	begin
				$display("OP_OR_RI R%02x|=%04x",instruction[8:6],instruction[17:9]);
				r[instruction[8:6]]=r[instruction[8:6]] | instruction[17:9];
				end
		`OP_XOR_RR:	begin
				$display("OP_XOR_RR R%02x^=R%02x",instruction[11:9],instruction[8:6]);
				r[instruction[11:9]]=r[instruction[11:9]] ^ r[instruction[8:6]];
				end
		`OP_XOR_RI:	begin
				$display("OP_XOR_RI R%02x^=%04x",instruction[8:6],instruction[17:9]);
				r[instruction[8:6]]=r[instruction[8:6]] ^ instruction[17:9];
				end
		`OP_SHL_RR:	begin
				$display("OP_SHL_RR R%02x<<=R%02x",instruction[11:9],instruction[8:6]);
				r[instruction[11:9]]=r[instruction[11:9]] << r[instruction[8:6]];
				end
		`OP_SHL_RI:	begin
				$display("OP_SHL_RI R%02x|=%04x",instruction[8:6],instruction[17:9]);
				r[instruction[8:6]]=r[instruction[8:6]] << instruction[17:9];
				end
		`OP_SHR_RR:	begin
				$display("OP_SHR_RR R%02x>>=R%02x",instruction[11:9],instruction[8:6]);
				r[instruction[11:9]]=r[instruction[11:9]] >> r[instruction[8:6]];
				end
		`OP_SHR_RI:	begin
				$display("OP_SHR_RI R%02x>>=%04x",instruction[8:6],instruction[17:9]);
				r[instruction[8:6]]=r[instruction[8:6]] >> instruction[17:9];
				end

		`OP_CMP_RR:	begin
				$display("OP_CMP_RR R%02x,R%02x",instruction[11:9],instruction[8:6]);
				if (r[instruction[11:9]]<r[instruction[8:6]]) `SFLAG=1;
				if (r[instruction[11:9]]>r[instruction[8:6]]) `GFLAG=1;
				if (r[instruction[11:9]]==r[instruction[8:6]]) `ZFLAG=1;
				end
		`OP_CMP_RI:	begin
				$display("OP_CMP_RI R%02x,%04x",instruction[8:6],instruction[17:9]);
				if (r[instruction[8:6]]<instruction[17:9]) `SFLAG=1;
				if (r[instruction[8:6]]>instruction[17:9]) `GFLAG=1;
				if (r[instruction[8:6]]==instruction[17:9]) `ZFLAG=1;
				end
		`OP_JL_I:	begin
				$display("OP_JL_I (%1d) %04x",instruction[17:17],instruction[16:6]);
				if (`SFLAG==1)
				if (instruction[17:17]==1) // Sign!
					`program_counter=`program_counter-instruction[16:6];
				else 	`program_counter=`program_counter+instruction[16:6];
				end
		`OP_JG_I:	begin
				$display("OP_JG_I (%1d) %04x",instruction[17:17],instruction[16:6]);
				if (`GFLAG==1)
				if (instruction[17:17]==1) // Sign!
					`program_counter=`program_counter-instruction[16:6];
				else 	`program_counter=`program_counter+instruction[16:6];
				end
		`OP_JE_I:	begin
				$display("OP_JE_I (%1d) %04x",instruction[17:17],instruction[16:6]);
				if (`ZFLAG==1)
				if (instruction[17:17]==1) // Sign!
					`program_counter=`program_counter-instruction[16:6];
				else 	`program_counter=`program_counter+instruction[16:6];

				end
		`OP_JNE_I:	begin
				$display("OP_JNE_I (%1d) %04x",instruction[17:17],instruction[16:6]);
				if (`ZFLAG==0)
				if (instruction[17:17]==1) // Sign!
					`program_counter=`program_counter-instruction[16:6];
				else 	`program_counter=`program_counter+instruction[16:6];
				end
		`OP_JMP_R:	begin
				$display("OP_JMP_R R%01x",instruction[8:6]);
				`program_counter=r[instruction[8:6]];
				`ifdef SECURITY_
					land_flag=1;
				`endif
				end
		`OP_CALL_R:	begin
				$display("OP_CALL_R R%01x",instruction[8:6]);
					//Stack overflow?
				if (`call_stack_pointer==`call_stack_max-2)
					do_interrupt(`INT_CALL_STACK_OVERFLOW);
				else
					begin
					call_stack[`call_stack_pointer]=`program_counter;
					`call_stack_pointer=`call_stack_pointer+1;
					`program_counter=r[instruction[8:6]];
					`ifdef SECURITY_
						land_flag=1;
					`endif
					end
				end
		`OP_CALL_I:	begin
				$display("OP_CALL_R (%1d) %04x",instruction[17:17],instruction[16:6]);
					//Stack overflow?
				if (`call_stack_pointer==`call_stack_max-2)
					do_interrupt(`INT_CALL_STACK_OVERFLOW);
				else
					begin
					call_stack[`call_stack_pointer]=`program_counter;
					`call_stack_pointer=`call_stack_pointer+1;
					if (instruction[17:17]==1) // Sign!
						`program_counter=`program_counter-instruction[16:6];
					else 	`program_counter=`program_counter+instruction[16:6];
					end
				end
		`OP_RET:	begin
				$display("OP_RET");
					//Stack underflow?
				if (`call_stack_pointer==0)
					do_interrupt(`INT_CALL_STACK_UNDERFLOW);
				else
					begin
					`call_stack_pointer=`call_stack_pointer-1;
					`program_counter=call_stack[`call_stack_pointer]-1;
					end
				end
		`OP_LAND:	begin
				$display("OP_LAND (land_flag=%1d)",land_flag);
				`ifdef SECURITY_
					if (land_flag==0)
						do_interrupt(`INT_ILLEGAL_OPCODE);
					else	land_flag=0;
				`endif
				end
		default: begin 
			 $display("Invalid OP! %04X",instruction[5:0]);
			 // ILLEGAL OPCODE!
			 do_interrupt(`INT_ILLEGAL_OPCODE);
			 end
	endcase


	case (instruction[5:0]) // flags settings
	`OP_ADD_RR,`OP_ADD_RI,`OP_ADD_RM,`OP_SUB_RR,
	`OP_SUB_RI,`OP_SUB_RM,`OP_AND_RR,`OP_AND_RI,
	`OP_OR_RR,`OP_OR_RI,`OP_XOR_RR,`OP_XOR_RI,
	`OP_SHL_RR,`OP_SHL_RI,`OP_SHR_RR,`OP_SHR_RI:
			begin
			if (r[instruction[8:6]]==0) `ZFLAG=1'b1; else `ZFLAG=1'b0; //zero
			if (r[instruction[8:6]][`operand_width-1:`operand_width-1]==1'b1) //sign
				`SFLAG=1'b1; else `SFLAG=1'b0;
			`GFLAG=1'b0;
			end
		default: begin
			 end
	endcase
	end
	$display("Regs: pc:%02x r0:%02x r1:%02x r2:%02x r3:%02x r4:%02x r5:%02x r6:%02x r7:%02x sp:%02x",`program_counter,r[0],r[1],r[2],r[3],r[4],r[5],r[6],r[7],`call_stack_pointer);
	end

endmodule
