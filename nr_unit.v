module nr_unit(
    input clk,
	input reset,
	input [15:0] x,
	input [1:0] key,
	
	output reg [31:0] arg_q,
	input [31:0] recip_seed,
	input [31:0] rsqrt_seed,
	
	output reg [31:0] out_mant_q,
	output reg signed [9:0] final_exp,
	output reg done
);


localparam [31:0] ONE_Q   = 32'd65536;  // 1.0 in Q16.16 fixed-point (1 * 2^16)
localparam [31:0] TWO_Q   = 32'd131072; // 2.0 in Q16.16 fixed-point (2 * 2^16)
localparam [31:0] THREE_Q = 32'd196608; // 3.0 in Q16.16 fixed-point (3 * 2^16)

localparam [2:0] IDLE   = 3'd0;
localparam [2:0] UNPACK = 3'd1;
localparam [2:0] PREP   = 3'd2;
localparam [2:0] SEED   = 3'd3;
localparam [2:0] ITER1  = 3'd4;
localparam [2:0] ITER2  = 3'd5;
localparam [2:0] FINAL  = 3'd6;
localparam [2:0] DONE_S = 3'd7;

// addition 1
localparam [15:0] exp_in_MASK = 16'd32640;
localparam [15:0] mant_q_MASK = 16'd127;

reg [2:0] state;

reg [15:0] x_reg;
reg op_sqrt;

reg signed [9:0] exp_in;
reg signed [9:0] exp_work;
reg [31:0] mant_q;

reg [31:0] seed_q;
reg [31:0] y_q;

reg [31:0] term_q;
reg [31:0] factor_q;
reg [31:0] y_sq_q;

function [31:0] qmul;
    input [31:0] a;
    input [31:0] b;
    reg [63:0] prod, prod_lsb;
    begin
        // multiply
        prod = a * b;
        // round
        prod_lsb = prod + 32'h8000; // add half LSB
        qmul = prod_lsb[47:16]; // truncate
    end
endfunction

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state    <= IDLE;
        x_reg    <= 16'd0;
        op_sqrt  <= 1'b0;
        exp_in   <= 10'sd0;
        exp_work <= 10'sd0;
        mant_q   <= 32'd0;
        arg_q    <= 32'd0;
        seed_q   <= 32'd0;
        y_q      <= 32'd0;
        done     <= 1'b0;
    end else begin
        done <= 1'b0;

        case (state)
            IDLE: begin
                if ((key == 2'b01) || (key == 2'b10)) begin
                    x_reg   <= x;
                    op_sqrt <= (key == 2'b01);
                    state   <= UNPACK;
                end
            end

            UNPACK: begin
                // unpack logic
                // set exp_in and mant_q
                // FE: ARE THESE THE SAME FOR EITHER CASE?
                exp_in =  exp_in_MASK & x; // exponent bits
                mant_q =  (mant_q_MASK & x) << 16; // mantissa (fraction) bits in the Q16.16 format

            end

            PREP: begin
                // prep logic
                // set arg_q and exp_work

                if (key == 2'b01) begin // CASE: sqrt --> arg_q === d  --> arg_q needs to be shifted value of the unpacked value of x?
                    arg_q = mantissa * (2 ** (exp_in - 127));  // we assume positive, and now this gives us the actual arg value
                    exp_work = exp_in - 127; // This is the working exponential (after the shift)
                end else if (key == 2'b10) begin
                    if (exp_in[0] == 0) begin
                        arg_q = ONE_Q;
                        exp_work = exp_in - 127; // This is the working exponential (after the shift)
                    end else if (exp_in[0] == 1) begin
                        arg_q = TWO_Q;
                        exp_work = exp_in - 127 - 1; // Subtract one extra for the two you put earlier in this case
			// FE: In this case, arg_q is the c value in the reciprocal?
		    end                
		end
            end

            SEED: begin
                // seed logic
                // set seed_q
                if (key == 2'b01) begin
                    seed_q = rsqrt_seed << 16;
                end else if (key == 2'b01) begin
                    seed_q = recip_seed << 16;
                end
            end

            ITER1: begin
                if (key == 2'b10) begin
                    // Reciprocal:
                    y_q <= qmul(seed_q, (TWO_Q - qmul(arg_q, seed_q)));
                end else if (key == 2'b01) begin
                    // Reciprocal square root:
                    y_q <= qmul(seed_q, (THREE_Q - qmul(arg_q,
                    qmul(seed_q, seed_q)))) >> 1;
                end
                state <= ITER2;
            end

            ITER2: begin
                // Repeat the same Newton--Raphson update using y_q.
                if (key == 2'b10) begin
                    // Reciprocal:
                    y_q <= qmul(seed_q, (TWO_Q - qmul(arg_q, seed_q)));
                end else if (key == 2'b01) begin
                    // Reciprocal square root:
                    y_q <= qmul(seed_q, (THREE_Q - qmul(arg_q,
                    qmul(seed_q, seed_q)))) >> 1;
                end
                state <= FINAL;
            end

            FINAL: begin
                // For square root: multiply argument by reciprocal square root estimate
                // For reciprocal: conditionally normalize mantissa if it falls below 1.0
                // For both: output out_mant_q and final_exp for pack_bfloat16 module
                if (key == 2'b10) begin // FE: I guess I just negate the exponent?
                    out_mant_q = y_q * arg_q;
                    final_exp = -exp_in;
                end else if (key == 2'b01) begin
                        out_mant_q = mant_q << 16; // FE: Still need to acutally normalize mantissa
		end
                state <= DONE_S;
            end

            DONE_S: begin
                done  <= 1'b1;
                state <= IDLE;
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule
