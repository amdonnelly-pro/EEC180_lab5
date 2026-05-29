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

localparam [31:0] ONE_Q   = 32'd65536;
localparam [31:0] TWO_Q   = 32'd131072;
localparam [31:0] THREE_Q = 32'd196608;

// FSM steps through the lab calculation instead of doing it all in one cycle.
localparam [3:0] IDLE      = 4'd0;
localparam [3:0] UNPACK    = 4'd1;
localparam [3:0] PREP      = 4'd2;
localparam [3:0] SEED      = 4'd3;
localparam [3:0] ITER_MUL1 = 4'd4;
localparam [3:0] ITER_MUL2 = 4'd5;
localparam [3:0] ITER_MUL3 = 4'd6;
localparam [3:0] FINAL     = 4'd7;
localparam [3:0] DONE_S    = 4'd8;

reg [3:0] state;
reg [15:0] x_reg;
reg op_sqrt;
reg iter_count;

reg signed [9:0] exp_in;
reg signed [9:0] exp_work;
reg [31:0] mant_q;
reg [31:0] y_q;
reg [31:0] term_q;
reg [31:0] y_sq_q;

reg [31:0] mul_a;
reg [31:0] mul_b;
wire [63:0] mul_prod;
wire [31:0] mul_q;

assign mul_prod = mul_a * mul_b;
assign mul_q = mul_prod[47:16];

// One shared Q16.16 multiplier. The state decides what gets multiplied.
always @* begin
    mul_a = 32'd0;
    mul_b = 32'd0;

    case (state)
        ITER_MUL1: begin
            if (op_sqrt) begin
                mul_a = y_q;
                mul_b = y_q;
            end else begin
                mul_a = arg_q;
                mul_b = y_q;
            end
        end

        ITER_MUL2: begin
            mul_a = arg_q;
            mul_b = y_sq_q;
        end

        ITER_MUL3: begin
            if (op_sqrt) begin
                mul_a = y_q >> 1;
                mul_b = THREE_Q - term_q;
            end else begin
                mul_a = y_q;
                mul_b = TWO_Q - term_q;
            end
        end

        FINAL: begin
            if (op_sqrt) begin
                mul_a = arg_q;
                mul_b = y_q;
            end
        end
    endcase
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        x_reg <= 16'd0;
        op_sqrt <= 1'b0;
        iter_count <= 1'b0;
        exp_in <= 10'sd0;
        exp_work <= 10'sd0;
        mant_q <= 32'd0;
        arg_q <= 32'd0;
        y_q <= 32'd0;
        term_q <= 32'd0;
        y_sq_q <= 32'd0;
        out_mant_q <= 32'd0;
        final_exp <= 10'sd0;
        done <= 1'b0;
    end else begin
        done <= 1'b0;

        case (state)
            IDLE: begin
                if ((key == 2'b01) || (key == 2'b10)) begin
                    x_reg <= x;
                    op_sqrt <= (key == 2'b01);
                    state <= UNPACK;
                end
            end

            UNPACK: begin
                // Split bfloat16 into exponent and mantissa, then convert mantissa to Q16.16.
                exp_in <= $signed({2'b00, x_reg[14:7]}) - 10'sd127;
                mant_q <= ONE_Q | ({25'd0, x_reg[6:0]} << 9);
                state <= PREP;
            end

            PREP: begin
                if (op_sqrt) begin
                    // For sqrt, make the exponent even so the mantissa stays in the ROM range.
                    if (exp_in[0]) begin
                        arg_q <= mant_q << 1;
                        exp_work <= (exp_in - 10'sd1) >>> 1;
                    end else begin
                        arg_q <= mant_q;
                        exp_work <= exp_in >>> 1;
                    end
                end else begin
                    arg_q <= mant_q;
                    exp_work <= -exp_in;
                end
                state <= ITER_MUL1;
					 
					 y_q <= op_sqrt ? rsqrt_seed : recip_seed;
					 iter_count <= 1'b0;
					 
            end

            ITER_MUL1: begin
                if (op_sqrt) begin
                    y_sq_q <= mul_q;
                    state <= ITER_MUL2;
                end else begin
                    term_q <= mul_q;
                    state <= ITER_MUL3;
                end
            end

            ITER_MUL2: begin
                term_q <= mul_q;
                state <= ITER_MUL3;
            end

            ITER_MUL3: begin
                y_q <= mul_q;
                if (iter_count == 1'b0) begin
                    iter_count <= 1'b1;
                    state <= ITER_MUL1;
                end else begin
                    state <= FINAL;
                end
            end

            FINAL: begin
                if (op_sqrt) begin
                    // sqrt(x) = x * rsqrt(x), so this turns the final rsqrt into sqrt.
                    out_mant_q <= mul_q;
                    final_exp <= exp_work;
                end else if (y_q < ONE_Q) begin
                    out_mant_q <= y_q << 1;
                    final_exp <= exp_work - 10'sd1;
                end else begin
                    out_mant_q <= y_q;
                    final_exp <= exp_work;
                end
                state <= DONE_S;
            end

            DONE_S: begin
                done <= 1'b1;
                state <= IDLE;
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule
