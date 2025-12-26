# Tang Nano 9K HDMI Driver

A lightweight, bare-metal HDMI transmitter implementation for the **Sipeed Tang Nano 9K** (Gowin GW1NR-9) FPGA.

This project provides a stable, phase-aligned 640x480 @ 60Hz video signal using the Gowin `OSER10` serialization primitives.

## Features
* **Resolution:** 640x480 @ 60Hz (Standard VGA Timing).
* **Interface:** Pure HDMI (TMDS Encoding + 10:1 Serialization).
* **Clocking:** Daisy-chained clock tree to prevent phase skew.
    * Input: 27 MHz (Onboard Crystal).
    * Serial Clock: 126 MHz.
    * Pixel Clock: 25.2 MHz.
* **Hardware Primitives:** Uses `ELVDS_OBUF` and `OSER10` for maximum signal integrity.

## Hardware Requirements
* **Board:** Sipeed Tang Nano 9K.
* **Connector:** On-board HDMI port.
* **IDE:** Gowin EDA.

## File Structure
```text
src/
├── hdmi_top.v        # Top-level wrapper (Instantiates PLL, Timing, and Serializers)
├── video_timing.v    # VGA Signal Generator (Generates x, y, h_sync, v_sync)
├── tmds_encoder.v    # 8b/10b TMDS Encoder (Converts 8-bit color to 10-bit symbols)
└── hdmi.cst          # Physical Constraints (Crucial for 1.8V Bank settings)
```

## Ontegration Guide
To use this driver in your own project, simply instantiate the top module and feed it 8-bit RGB values.

```verilog
module my_project_top (
    input clk_27m,
    input rst_n,
    output [3:0] tmds_d_p,
    output [3:0] tmds_d_n
);

    // 1. Signals
    wire [9:0] x, y;
    wire active;
    
    // 2. Your Logic Here
    // Example: Generate a solid color pattern
    wire [7:0] r = active ? 8'hFF : 0; // Red
    wire [7:0] g = 0;
    wire [7:0] b = 0;

    // 3. Instantiate Driver
    hdmi_top u_hdmi (
        .clk_27m(clk_27m),
        .rst_n(rst_n),
        // Video Inputs
        .red_in(r),
        .green_in(g),
        .blue_in(b),
        // Coordinate Outputs (Use these to decide what to draw!)
        .x_out(x),
        .y_out(y),
        .active_out(active),
        // Physical Pins
        .tmds_clk_p(tmds_d_p[3]), .tmds_clk_n(tmds_d_n[3]),
        .tmds_d_p(tmds_d_p[2:0]), .tmds_d_n(tmds_d_n[2:0])
    );

endmodule
```

## Critical Constraints
The Tang Nano 9K HDMI pins are located on Banks 1 and 2, which are powered at **1.8V**. You **must** use the `LVCMOS18D` IO type in your constraint file (`.cst`), or the signals will not drive correctly.

```hcl
// HDMI Data Lanes
IO_LOC "tmds_d_p[0]" 71,70;
IO_PORT "tmds_d_p[0]" IO_TYPE=LVCMOS18D PULL_MODE=NONE DRIVE=8;
IO_LOC "tmds_d_p[1]" 73,72;
IO_PORT "tmds_d_p[1]" IO_TYPE=LVCMOS18D PULL_MODE=NONE DRIVE=8;
IO_LOC "tmds_d_p[2]" 75,74;
IO_PORT "tmds_d_p[2]" IO_TYPE=LVCMOS18D PULL_MODE=NONE DRIVE=8;

// HDMI Clock Lane
IO_LOC "tmds_clk_p" 69,68;
IO_PORT "tmds_clk_p" IO_TYPE=LVCMOS18D PULL_MODE=NONE DRIVE=8;
```

## Common Issues & Fixes
* **No Signal / Black Screen:**
    * Check if your PLL Lock is resetting the logic.
    * Verify `ELVDS_OBUF` is used (not `TLVDS`).
    * Ensure the Pixel Clock is derived from the Serial Clock divider (Daisy Chain) to avoid clock skew.
* **Sparkles / Noise:**
    * Likely a timing violation. Check that your logic feeding the RGB inputs meets the 25.2 MHz timing requirement.

## License
MIT License.
