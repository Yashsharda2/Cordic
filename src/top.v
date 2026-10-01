`default_nettype none

// top
//   SPI mode 0, 16-bit words, MSB first. Frame protocol (CS low):
//     word 0 : MOSI = angle (32768 = 180 deg)   MISO = cos of the PREVIOUS run
//     word 1 : MOSI = don't care                MISO = sin of the CURRENT angle
//   The CORDIC starts on the last SCK sample edge of word 0. 
//   before the last shift edge of word 0, i.e. one SCK half-period later:
//     SCK half-period >= ~20 clk cycles  ->  f_sck <= f_clk / 40
//     (f_clk = 10 MHz  ->  f_sck <= 250 kHz)

module top (
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire i_ss_n,
    input  wire i_sck,
    input  wire i_mosi,
    output wire o_miso,
    output wire o_cordic_done
);

    wire        w_cs_active;
    wire        w_rx_valid;
    wire [15:0] w_rx_data;
    wire [15:0] w_tx_data;
    wire [15:0] w_cos;
    wire [15:0] w_sin;

    // frame: 0 = angle/cos word, 1 = dummy/sin word
    reg r_word_sel;

    always @(posedge i_clk) begin
        if (!i_rst_n)          r_word_sel <= 1'b0;
        else if (!w_cs_active) r_word_sel <= 1'b0;
        else if (w_rx_valid)   r_word_sel <= ~r_word_sel;
    end

    wire w_cordic_start = w_rx_valid & ~r_word_sel;
    assign w_tx_data    = r_word_sel ? w_sin : w_cos;

    spi_target #(
        .CPOL  (1'b0),
        .CPHA  (1'b0),
        .WIDTH (16),
        .LSB   (1'b0)
    ) u_spi_target (
        .i_clk           (i_clk),
        .i_rst_n         (i_rst_n),
        .i_ss_n          (i_ss_n),
        .i_sck           (i_sck),
        .i_mosi          (i_mosi),
        .o_miso          (o_miso),
        .o_cs_active     (w_cs_active),
        .o_rx_data       (w_rx_data),
        .o_rx_data_valid (w_rx_valid),
        .i_tx_data       (w_tx_data)
    );

    cordic_circular u_cordic (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_start (w_cordic_start),
        .i_angle (w_rx_data),
        .o_cos   (w_cos),
        .o_sin   (w_sin),
        .o_done  (o_cordic_done)
    );

endmodule
`default_nettype wire
