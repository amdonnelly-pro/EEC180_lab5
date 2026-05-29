// 32 bfloat16 test inputs for the FPGA demo.
module ram32x16(
    input [4:0] addr,
    output reg [15:0] data
);
    always @(*) begin
        case (addr)
            // These are data values, not addresses. Example: 4080 means 4.0.
            5'd0:  data = 16'h3f80; // 1.0
            5'd1:  data = 16'h4000; // 2.0
            5'd2:  data = 16'h4080; // 4.0
            5'd3:  data = 16'h3f00; // 0.5
            5'd4:  data = 16'h4040; // 3.0
            5'd5:  data = 16'h3fc0; // 1.5
            5'd6:  data = 16'h3fff; // near 2.0
            5'd7:  data = 16'h0080; // minimum normal
            5'd8:  data = 16'h7e80; // max reciprocal safe case from TA testbench
            5'd9:  data = 16'h7f7f; // maximum finite bfloat16
            5'd10: data = 16'h3e80; // 0.25
            5'd11: data = 16'h4100; // 8.0
            5'd12: data = 16'h4180; // 16.0
            5'd13: data = 16'h4200; // 32.0
            5'd14: data = 16'h4280; // 64.0
            5'd15: data = 16'h4300; // 128.0
            5'd16: data = 16'h3f40; // 0.75
            5'd17: data = 16'h3fa0; // 1.25
            5'd18: data = 16'h4020; // 2.5
            5'd19: data = 16'h4060; // 3.5
            5'd20: data = 16'h40a0; // 5.0
            5'd21: data = 16'h40c0; // 6.0
            5'd22: data = 16'h40e0; // 7.0
            5'd23: data = 16'h3d80; // 0.0625
            5'd24: data = 16'h3c80; // 0.015625
            5'd25: data = 16'h4480; // 1024.0
            5'd26: data = 16'h4580; // 4096.0
            5'd27: data = 16'h4a80; // 4194304.0
            5'd28: data = 16'h3380; // small normal
            5'd29: data = 16'h6000; // large normal
            5'd30: data = 16'h7000; // very large normal
            5'd31: data = 16'h7f00; // large finite edge
        endcase
    end
endmodule
