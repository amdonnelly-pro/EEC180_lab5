import math

Q = 1 << 16


def nr_reciprocal(m, iters, seed):
    y = seed
    for _ in range(iters):
        y = y * (2.0 - m * y)
    return y


def nr_rsqrt(m, iters, seed):
    y = seed
    for _ in range(iters):
        y = 0.5 * y * (3.0 - m * y * y)
    return y


def quantize_q16(x):
    return int(round(x * Q))


def generate_recip_seed_table(entries=32):
    table = []
    for i in range(entries):
        left = 1.0 + i / entries
        right = 1.0 + (i + 1) / entries
        midpoint = 0.5 * (left + right)
        seed = 1.0 / midpoint
        table.append(quantize_q16(seed))
    return table


def generate_rsqrt_seed_table(entries=32):
    table = []
    for i in range(entries):
        left = 1.0 + 3.0 * i / entries
        right = 1.0 + 3.0 * (i + 1) / entries
        midpoint = 0.5 * (left + right)
        seed = 1.0 / math.sqrt(midpoint)
        table.append(quantize_q16(seed))
    return table


def print_verilog_case_table(name, values):
    print("module %s_rom (" % name)
    print(" input [31:0] in_q,")
    print(" output reg [31:0] %s_seed" % name)
    print(");")
    print("")
    print("localparam [31:0] ONE_Q   = 32'd65536;")
    print("localparam [31:0] TWO_Q   = 32'd131072;")
    print("localparam [31:0] THREE_Q = 32'd196608;")
    print("")
    print("wire [4:0] %s_idx;" % name)
    if name == "recip":
        print("assign recip_idx = (in_q <= ONE_Q) ? 5'd0 :")
        print("                   (in_q >= (TWO_Q - 32'd2048)) ? 5'd31 :")
        print("                   ((in_q - ONE_Q) >> 11);")
    elif name == "rsqrt":
        print("assign rsqrt_idx = (in_q <= ONE_Q) ? 5'd0 :")
        print("                   (in_q >= (32'd262144 - 32'd6144)) ? 5'd31 :")
        print("                   ((in_q - ONE_Q) / 32'd6144);")
    else:
        print("// Determine how to get the idx from the input")
        print("assign %s_idx = 5'd0;" % name)
    print("")
    print("always @ (%s_idx) begin" % name)
    print(" case (%s_idx)" % name)
    for i, value in enumerate(values):
        print(" 5'd%d: %s_seed = 32'd%d;" % (i, name, value))
    print(" default: %s_seed = 32'd%d;" % (name, values[-1]))
    print(" endcase")
    print(" end")
    print("endmodule")


if __name__ == "__main__":
    recip = generate_recip_seed_table()
    rsqrt = generate_rsqrt_seed_table()

    print("Reciprocal seed table (Q16):")
    print(recip)
    print()

    print("Reciprocal square-root seed table (Q16):")
    print(rsqrt)
    print()

    print_verilog_case_table("recip", recip)
    print()
    print_verilog_case_table("rsqrt", rsqrt)
