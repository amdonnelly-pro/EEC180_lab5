// Board wrapper for the DE10-Lite demo part of the lab.
module top(
    input MAX10_CLK1_50,
    input [9:0] SW,
    input [1:0] KEY,
    output [9:0] LEDR,
    output [7:0] HEX0,
    output [7:0] HEX1,
    output [7:0] HEX2,
    output [7:0] HEX3,
    output [7:0] HEX4,
    output [7:0] HEX5
);
    wire reset;
    wire [15:0] x_value;
    wire [15:0] y_value;
    wire [15:0] display_value;
    wire [1:0] op_key;
    wire done_pulse;
    wire valid_op;
    wire [6:0] selected_case;

    reg done_seen;
    reg [6:0] previous_case;

    // KEY buttons are active low, so pressing KEY0 resets the circuit.
    assign reset = ~KEY[0];
    assign op_key = SW[6:5];
    assign valid_op = (op_key == 2'b01) || (op_key == 2'b10);
    assign selected_case = {op_key, SW[4:0]};

    // SW9 lets me check the input value or the computed output value.
    assign display_value = SW[9] ? x_value : y_value;

    // SW[4:0] is the address. The value stored there is the bfloat16 input.
    ram32x16 input_ram (
        .addr(SW[4:0]),
        .data(x_value)
    );

    top_level core (
        .clk(MAX10_CLK1_50),
        .reset(reset),
        .x(x_value),
        .key(valid_op ? op_key : 2'b00),
        .y(y_value),
        .done(done_pulse)
    );

    always @(posedge MAX10_CLK1_50 or posedge reset) begin
        if (reset) begin
            done_seen <= 1'b0;
            previous_case <= 7'd0;
        end else begin
            previous_case <= selected_case;
            // done is only one clock long, so LEDR9 holds it until I clear/change it.
            if (!KEY[1] || (selected_case != previous_case)) begin
                done_seen <= 1'b0;
            end else if (done_pulse) begin
                done_seen <= 1'b1;
            end
        end
    end

    // HEX3..HEX0 shows the 16-bit bfloat16 number in hex.
    hex7seg y3_display (.value(display_value[15:12]), .segments(HEX3[6:0]));
    hex7seg y2_display (.value(display_value[11:8]),  .segments(HEX2[6:0]));
    hex7seg y1_display (.value(display_value[7:4]),   .segments(HEX1[6:0]));
    hex7seg y0_display (.value(display_value[3:0]),   .segments(HEX0[6:0]));

    assign HEX5 = 8'hFF;
    assign HEX4 = 8'hFF;
    assign HEX3[7] = 1'b1;
    assign HEX2[7] = 1'b1;
    assign HEX1[7] = 1'b1;
    assign HEX0[7] = 1'b1;

    assign LEDR[4:0] = SW[4:0];
    assign LEDR[6:5] = op_key;
    assign LEDR[7] = valid_op | SW[7];
    assign LEDR[8] = done_pulse | SW[8];
    assign LEDR[9] = done_seen;
endmodule
