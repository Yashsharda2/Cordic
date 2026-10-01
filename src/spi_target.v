`default_nettype none

// spi_target
//   - synchronous active-low reset (i_rst_n)
//   - SCK, SS_N and MOSI are all 2-FF synchronized; edge detect uses a 3rd flop
//   - All shift / count / valid logic is gated by the synchronized CS
//   - Requirement: i_clk >= ~6x SCK for reliable edge detection (WIDTH >= 2)

module spi_target #(
    parameter CPOL  = 1'b0,  // idle clock level: 0 = low, 1 = high
    parameter CPHA  = 1'b0,  // 0 = sample on leading edge, 1 = trailing edge
    parameter WIDTH = 8,     // bits per word (>= 2)
    parameter LSB   = 1'b0   // 0 = MSB first, 1 = LSB first
) (
    input  wire             i_clk,
    input  wire             i_rst_n,

    // SPI pins (asynchronous to i_clk)
    input  wire             i_ss_n,
    input  wire             i_sck,
    input  wire             i_mosi,
    output wire             o_miso,

    output wire             o_cs_active,      // synchronized, 1 while CS is low
    output reg  [WIDTH-1:0] o_rx_data,
    output reg              o_rx_data_valid,  // 1-clk pulse, o_rx_data is complete
    input  wire [WIDTH-1:0] i_tx_data         // sampled when a new word is loaded
);

    localparam                CNT_W    = $clog2(WIDTH);
    localparam [CNT_W-1:0]    LAST_BIT = WIDTH - 1;

    // Input synchronizers
    
    reg [2:0] r_ss_n_sync;   // [0],[1] = synchronizer, [2] = previous value
    reg [2:0] r_sck_sync;
    reg [1:0] r_mosi_sync;   // [1] is time-aligned with r_sck_sync[1]

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            r_ss_n_sync <= 3'b111;
            r_sck_sync  <= {3{CPOL[0]}};   // idle level
            r_mosi_sync <= 2'b00;
        end else begin
            r_ss_n_sync <= {r_ss_n_sync[1:0], i_ss_n};
            r_sck_sync  <= {r_sck_sync[1:0],  i_sck};
            r_mosi_sync <= {r_mosi_sync[0],   i_mosi};
        end
    end

    // Edge / phase decode

    wire w_sck_rise = ~r_sck_sync[2] &  r_sck_sync[1];
    wire w_sck_fall =  r_sck_sync[2] & ~r_sck_sync[1];
    wire w_cs_fall  =  r_ss_n_sync[2] & ~r_ss_n_sync[1];

    assign o_cs_active = ~r_ss_n_sync[1];

    wire w_sample_edge = (CPHA ^ CPOL) ? w_sck_fall : w_sck_rise;
    wire w_shift_edge  = (CPHA ^ CPOL) ? w_sck_rise : w_sck_fall;

    wire w_sample = w_sample_edge & o_cs_active;
    wire w_shift  = w_shift_edge  & o_cs_active;

    // Bit counter 

    reg [CNT_W-1:0] r_bit_cnt;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            r_bit_cnt <= {CNT_W{1'b0}};
        end else if (!o_cs_active) begin
            r_bit_cnt <= {CNT_W{1'b0}};
        end else if (w_sample) begin
            if (r_bit_cnt == LAST_BIT) r_bit_cnt <= {CNT_W{1'b0}};
            else                       r_bit_cnt <= r_bit_cnt + 1'b1;
        end
    end

    // RX: shift MOSI in on the sample edge

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            o_rx_data       <= {WIDTH{1'b0}};
            o_rx_data_valid <= 1'b0;
        end else begin
            o_rx_data_valid <= w_sample && (r_bit_cnt == LAST_BIT);
            if (w_sample) begin
                if (LSB) o_rx_data <= {r_mosi_sync[1], o_rx_data[WIDTH-1:1]};
                else     o_rx_data <= {o_rx_data[WIDTH-2:0], r_mosi_sync[1]};
            end
        end
    end

    // TX: load a new word at CS fall (CPHA=0) or at each word boundary, shift on the opposite edge
    reg [WIDTH-1:0] r_miso_data;

    wire w_tx_load = ((CPHA == 1'b0) & w_cs_fall) |
                     (w_shift & (r_bit_cnt == {CNT_W{1'b0}}));

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            r_miso_data <= {WIDTH{1'b0}};
        end else if (w_tx_load) begin
            r_miso_data <= i_tx_data;
        end else if (w_shift) begin
            if (LSB) r_miso_data <= r_miso_data >> 1;
            else     r_miso_data <= r_miso_data << 1;
        end
    end

    assign o_miso = LSB ? r_miso_data[0] : r_miso_data[WIDTH-1];

endmodule
`default_nettype wire
