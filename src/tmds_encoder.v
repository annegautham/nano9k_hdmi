module tmds_encoder (
    input  wire clk,
    input  wire [7:0] data,
    input  wire [1:0] ctrl,
    input  wire active,
    output reg  [9:0] tmds
);
    wire [3:0] n1d = data[0] + data[1] + data[2] + data[3] + data[4] + data[5] + data[6] + data[7];
    wire use_xnor = (n1d > 4) || (n1d == 4 && data[0] == 0);
    wire [8:0] q_m;

    assign q_m[0] = data[0];
    assign q_m[1] = use_xnor ? (q_m[0] ~^ data[1]) : (q_m[0] ^ data[1]);
    assign q_m[2] = use_xnor ? (q_m[1] ~^ data[2]) : (q_m[1] ^ data[2]);
    assign q_m[3] = use_xnor ? (q_m[2] ~^ data[3]) : (q_m[2] ^ data[3]);
    assign q_m[4] = use_xnor ? (q_m[3] ~^ data[4]) : (q_m[3] ^ data[4]);
    assign q_m[5] = use_xnor ? (q_m[4] ~^ data[5]) : (q_m[4] ^ data[5]);
    assign q_m[6] = use_xnor ? (q_m[5] ~^ data[6]) : (q_m[5] ^ data[6]);
    assign q_m[7] = use_xnor ? (q_m[6] ~^ data[7]) : (q_m[6] ^ data[7]);
    assign q_m[8] = use_xnor ? 0 : 1;

    reg signed [4:0] bias = 0;
    wire [3:0] n1q_m = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
    wire [3:0] n0q_m = 8 - n1q_m;

    always @(posedge clk) begin
        if (!active) begin
            bias <= 0;
            case (ctrl)
                2'b00:   tmds <= 10'b1101010100;
                2'b01:   tmds <= 10'b0010101011;
                2'b10:   tmds <= 10'b0101010110;
                default: tmds <= 10'b1010101011;
            endcase
        end else begin
            if (bias == 0 || n1q_m == n0q_m) begin
                tmds <= {~q_m[8], q_m[8], (q_m[8] ? q_m[7:0] : ~q_m[7:0])};
                if (q_m[8] == 0) bias <= bias + (n0q_m - n1q_m);
                else bias <= bias + (n1q_m - n0q_m);
            end else if ((bias > 0 && n1q_m > n0q_m) || (bias < 0 && n0q_m > n1q_m)) begin
                tmds <= {1'b1, q_m[8], ~q_m[7:0]};
                bias <= bias + q_m[8] - (n1q_m - n0q_m);
            end else begin
                tmds <= {1'b0, q_m[8], q_m[7:0]};
                bias <= bias - (~q_m[8]) + (n1q_m - n0q_m);
            end
        end
    end
endmodule