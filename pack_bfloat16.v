module pack_bfloat16(
	input [9:0] exp_unbiased,
	input [31:0] mantissa_q,
	output [15:0] packed_out
);
	packed_out[15] = 1'b0; // will always be zero in our implementation
	packed_out[14:7] = exp_unbiased; 
	packed_out[6:0] = mantissa_q >> 16; // Why is the mantissa so large (16 bits) in 
					    // top level?
endmodule
