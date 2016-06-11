
//Basic definitions
`define operand_width 16 ///< Operand width 

`define code_width 18 // Xilinx block ram
`define code_depth 10 // 1024 instructions
`define code_size (1<<`code_depth) ///< Instruction memory size

`define reset_vector 0 ///< Reset vector

`define data_width `code_width ///< Port IO data width
`define data_depth 9 ///< Port id (address) width
`define data_size (1<<`data_depth) ///< Port size

`define stack_
`define call_stack_max 128
`define SECURITY_

// Interruption codes
`define INT_ILLEGAL_OPCODE 		'h10
`define INT_CALL_STACK_OVERFLOW 	'h20
`define INT_CALL_STACK_UNDERFLOW 	'h30
`define INT_RANGE_CHECK_ERROR 		'h40
`define INT_INVALID_CALL		'h50

// Operation codes
`define OP_NOP   00

`define OP_MOV_RR 01
`define OP_MOV_RI 02
`define OP_MOV_RM 03
`define OP_MOV_MR 04

`define OP_MOV_RS 05
`define OP_MOV_SR 06

`define OP_ADD_RR 07
`define OP_ADD_RI 08
`define OP_ADD_RM 09

`define OP_SUB_RR 11
`define OP_SUB_RI 12
`define OP_SUB_RM 13

`define OP_AND_RR 15
`define OP_AND_RI 16

`define OP_OR_RR  17
`define OP_OR_RI  18

`define OP_XOR_RR 19
`define OP_XOR_RI 20

`define OP_SHL_RR 23
`define OP_SHL_RI 24

`define OP_SHR_RR 25
`define OP_SHR_RI 26

`define OP_CMP_RR 27
`define OP_CMP_RI 28

`define OP_JMP_R 31
//`define OP_JMP_M 33

`define OP_JL_I  34
`define OP_JG_I  35
`define OP_JE_I  36
`define OP_JNE_I 37

`define OP_CALL_R  38
`define OP_CALL_I  39
`define OP_RET  40
`define OP_LAND  41

