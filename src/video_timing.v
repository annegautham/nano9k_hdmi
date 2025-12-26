module video_timing (
    input  wire pclk,
    input  wire rst_n,
    output reg  h_sync,
    output reg  v_sync,
    output reg  active_video,
    output reg  [9:0] x,
    output reg  [9:0] y
);
    // 640x480 @ 60Hz parameters
    parameter H_ACTIVE = 640;
    parameter H_FP     = 16;
    parameter H_SYNC   = 96;
    parameter H_BP     = 48;
    parameter H_TOTAL  = 800;

    parameter V_ACTIVE = 480;
    parameter V_FP     = 10;
    parameter V_SYNC   = 2;
    parameter V_BP     = 33;
    parameter V_TOTAL  = 525;

    reg [9:0] h_cnt, v_cnt;

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1) v_cnt <= 0;
                else v_cnt <= v_cnt + 1;
            end else h_cnt <= h_cnt + 1;
        end
    end

    always @(posedge pclk) begin
        h_sync <= ~(h_cnt >= (H_ACTIVE + H_FP) && h_cnt < (H_ACTIVE + H_FP + H_SYNC));
        v_sync <= ~(v_cnt >= (V_ACTIVE + V_FP) && v_cnt < (V_ACTIVE + V_FP + V_SYNC));
        active_video <= (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
        x <= (h_cnt < H_ACTIVE) ? h_cnt : 0;
        y <= (v_cnt < V_ACTIVE) ? v_cnt : 0;
    end
endmodule