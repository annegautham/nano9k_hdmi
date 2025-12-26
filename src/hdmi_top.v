module hdmi_top (
    input  wire clk_27m,
    input  wire rst_n,
    output wire tmds_clk_p, tmds_clk_n,
    output wire [2:0] tmds_d_p, tmds_d_n
);
    wire vco_fclk;   // 504 MHz
    wire ser_fclk;   // 126 MHz
    wire pclk;       // 25.2 MHz
    wire pll_lock;

    // 1. PLL: Generates only the high-speed VCO (504 MHz)
    Gowin_rPLL your_pll_inst (
        .clkin(clk_27m),
        .clkout(vco_fclk), // 504 MHz
        .lock(pll_lock),
        .reset(!rst_n)     // Check your IP: usually active high reset
    );

    // 2. CLKDIV 1: 504 MHz -> 126 MHz (Serial Clock)
    // Divides by 4
    CLKDIV #(.DIV_MODE("4")) u_div_serial (
        .CLKOUT(ser_fclk),
        .HCLKIN(vco_fclk),
        .RESETN(pll_lock)
    );

    // 3. CLKDIV 2: 126 MHz -> 25.2 MHz (Pixel Clock)
    // Divides by 5. THIS IS THE CRITICAL FIX.
    // It takes the *already divided* ser_fclk as input.
    CLKDIV #(.DIV_MODE("5")) u_div_pixel (
        .CLKOUT(pclk),
        .HCLKIN(ser_fclk), // Chain from the serial clock
        .RESETN(pll_lock)
    );


    // Video Timing
    wire [9:0] x, y;
    wire h_sync, v_sync, active;
    video_timing u_timing (
        .pclk(pclk), 
        .rst_n(pll_lock),
        .h_sync(h_sync), .v_sync(v_sync), .active_video(active),
        .x(x), .y(y)
    );

    // Fixed Color Test (Solid Red to verify signal first)
    wire [7:0] red   = active ? (x < 10'd320 ? 8'hFF : 8'h00) : 8'd0;
    wire [7:0] green = 8'd0;
    wire [7:0] blue  = active ? (x >= 10'd320 ? 8'hFF : 8'h00) : 8'd0;
    // TMDS Encoders
    wire [9:0] tmds_red, tmds_green, tmds_blue;
    tmds_encoder enc_r (.clk(pclk), .data(red),   .ctrl(2'b00),           .active(active), .tmds(tmds_red));
    tmds_encoder enc_g (.clk(pclk), .data(green), .ctrl(2'b00),           .active(active), .tmds(tmds_green));
    tmds_encoder enc_b (.clk(pclk), .data(blue),  .ctrl({v_sync,h_sync}), .active(active), .tmds(tmds_blue));

    // Serialization
    wire [2:0] tmds_serialized;
    wire tmds_clk_serialized;

    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : ser_data
            wire [9:0] tmds_val = (i==0) ? tmds_blue : (i==1) ? tmds_green : tmds_red;
            OSER10 u_oser (
                .Q(tmds_serialized[i]), 
                .D0(tmds_val[0]), .D1(tmds_val[1]), .D2(tmds_val[2]), .D3(tmds_val[3]), .D4(tmds_val[4]), 
                .D5(tmds_val[5]), .D6(tmds_val[6]), .D7(tmds_val[7]), .D8(tmds_val[8]), .D9(tmds_val[9]), 
                .FCLK(ser_fclk), // 126 MHz
                .PCLK(pclk),     // 25.2 MHz
                .RESET(!pll_lock)
            );
            ELVDS_OBUF u_buf_data (.I(tmds_serialized[i]), .O(tmds_d_p[i]), .OB(tmds_d_n[i]));
        end
    endgenerate

    // Clock Lane
    OSER10 u_oser_clk (
        .Q(tmds_clk_serialized), 
        .D0(1'b1), .D1(1'b1), .D2(1'b1), .D3(1'b1), .D4(1'b1), 
        .D5(1'b0), .D6(1'b0), .D7(1'b0), .D8(1'b0), .D9(1'b0), 
        .FCLK(ser_fclk), 
        .PCLK(pclk), 
        .RESET(!pll_lock)
    );
    ELVDS_OBUF u_buf_clk (.I(tmds_clk_serialized), .O(tmds_clk_p), .OB(tmds_clk_n));

endmodule