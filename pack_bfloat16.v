module pack_bfloat16(
	input signed [9:0] exp_unbiased,
	input [31:0] mantissa_q,
	output reg [15:0] packed_out
);

localparam [31:0] ONE_Q = 32'd65536;
localparam [31:0] TWO_Q = 32'd131072;

reg [31:0] norm_mant;
reg signed [10:0] norm_exp;
reg signed [10:0] biased_exp;
reg [8:0] rounded_sig;
reg [8:0] sub_sig;
reg [31:0] shifted_sig;
integer i;
integer shift_amount;

always @* begin
	packed_out = 16'h0000;
	norm_mant = mantissa_q;
	norm_exp = exp_unbiased;
	rounded_sig = 9'd0;
	sub_sig = 9'd0;
	shifted_sig = 32'd0;
	biased_exp = 11'sd0;
	shift_amount = 0;
	i = 0;

	if (norm_mant != 32'd0) begin
		// Move the Q16.16 mantissa back into the bfloat16 normal range.
		for (i = 0; i < 8; i = i + 1) begin
			if (norm_mant >= TWO_Q) begin
				norm_mant = norm_mant >> 1;
				norm_exp = norm_exp + 11'sd1;
			end else if (norm_mant < ONE_Q) begin
				norm_mant = norm_mant << 1;
				norm_exp = norm_exp - 11'sd1;
			end
		end

		biased_exp = norm_exp + 11'sd127;

		if (biased_exp >= 11'sd255) begin
			packed_out = 16'h7f7f;
		end else if (biased_exp <= 11'sd0) begin
			// Very tiny answers become bfloat16 subnormals instead of just breaking.
			shift_amount = 10 - biased_exp;
			if (shift_amount >= 32) begin
				packed_out = 16'h0000;
			end else begin
				shifted_sig = (norm_mant + (32'd1 << (shift_amount - 1))) >> shift_amount;
				sub_sig = shifted_sig[8:0];
				if (sub_sig >= 9'd128) begin
					packed_out = 16'h0080;
				end else begin
					packed_out = {1'b0, 8'd0, sub_sig[6:0]};
				end
			end
		end else begin
			// Round Q16.16 back down to bfloat16 precision.
			shifted_sig = (norm_mant + 32'd256) >> 9;
			rounded_sig = shifted_sig[8:0];
			if (rounded_sig >= 9'd256) begin
				rounded_sig = 9'd128;
				norm_exp = norm_exp + 11'sd1;
				biased_exp = norm_exp + 11'sd127;
			end

			if (biased_exp >= 11'sd255) begin
				packed_out = 16'h7f7f;
			end else begin
				packed_out = {1'b0, biased_exp[7:0], rounded_sig[6:0]};
			end
		end
	end
end

endmodule
