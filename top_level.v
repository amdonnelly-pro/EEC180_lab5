module top_level (
    input clk, reset,
    input [15:0] x,
    input [1:0] key,
    output [15:0] y,
    output done
);

wire [31:0] rsqrt_seed, recip_seed;

wire [31:0] arg_q, mantissa_q;
wire signed [9:0] final_exp;

rsqrt_rom rsqrt_sd (
    .in_q(arg_q),
    .rsqrt_seed(rsqrt_seed)
);

recip_rom recip_sd (
    .in_q(arg_q),
    .recip_seed(recip_seed)
);

nr_unit fsm (
    .clk(clk),
    .reset(reset),
    .x(x),
    .key(key),
    
    .arg_q(arg_q),
    .recip_seed(recip_seed),
    .rsqrt_seed(rsqrt_seed),

    .final_exp(final_exp),
    .out_mant_q(mantissa_q),

    .done(done)
);

pack_bfloat16 pack (
    .exp_unbiased(final_exp),
    .mantissa_q(mantissa_q),
    .packed_out(y)
);

endmodule