`default_nettype none

// cordic_circular
//   Iterative, 15 iterations, gain pre-scaled.
//   i_angle : signed 16-bit, 32768 = 180 deg  (range -180 .. +180 deg)
//   o_cos   : signed Q1.15, saturated (cos(0) = 32767)    o_sin   : signed Q1.15, saturated
//   Latency : 1 (start) + 15 (rotate) + 1 (done) clocks
//   Pulse i_start for one clock while idle; o_done is a one-clock pulse and

module cordic_circular (
    input  wire               i_clk,
    input  wire               i_rst_n,
    input  wire               i_start,
    input  wire signed [15:0] i_angle,
    output reg  signed [15:0] o_cos,
    output reg  signed [15:0] o_sin,
    output reg                o_done
);

    localparam signed [17:0] HALF_PI  = 18'sd16384;  // 90 deg
    localparam signed [17:0] K_FACTOR = 18'sd19898;  // 1/gain * 2^15
    localparam        [3:0]  LAST_ITER = 4'd14;

    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_ROTATE = 2'd1;
    localparam [1:0] S_DONE   = 2'd2;

    reg [1:0]         r_state;
    reg [3:0]         r_iter;
    reg signed [17:0] r_x, r_y, r_z;

    wire signed [17:0] w_angle_ext = {{2{i_angle[15]}}, i_angle};

    // Saturate 18-bit -> 16-bit
   
    function signed [15:0] sat16;
        input signed [17:0] val;
        begin
            if (val > 18'sd32767)        sat16 = 16'sd32767;
            else if (val < -18'sd32768)  sat16 = -16'sd32768;
            else                         sat16 = val[15:0];
        end
    endfunction

    // atan(2^-i) lookup, same scale as i_angle (32768 = 180 deg)
 
    reg signed [15:0] r_atan_lut;

    always @(*) begin
        case (r_iter)
            4'd0:    r_atan_lut = 16'sd8192;  // 45.000 deg
            4'd1:    r_atan_lut = 16'sd4836;  // 26.565 deg
            4'd2:    r_atan_lut = 16'sd2555;  // 14.036 deg
            4'd3:    r_atan_lut = 16'sd1297;  //  7.125 deg
            4'd4:    r_atan_lut = 16'sd651;   //  3.576 deg
            4'd5:    r_atan_lut = 16'sd326;   //  1.790 deg
            4'd6:    r_atan_lut = 16'sd163;   //  0.895 deg
            4'd7:    r_atan_lut = 16'sd81;    //  0.448 deg
            4'd8:    r_atan_lut = 16'sd41;    //  0.224 deg
            4'd9:    r_atan_lut = 16'sd20;    //  0.112 deg
            4'd10:   r_atan_lut = 16'sd10;
            4'd11:   r_atan_lut = 16'sd5;
            4'd12:   r_atan_lut = 16'sd3;
            4'd13:   r_atan_lut = 16'sd1;
            4'd14:   r_atan_lut = 16'sd1;
            default: r_atan_lut = 16'sd0;
        endcase
    end

    wire signed [17:0] w_x_shift = r_x >>> r_iter;
    wire signed [17:0] w_y_shift = r_y >>> r_iter;

    // FSM + datapath
 
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            r_state <= S_IDLE;
            o_cos   <= 16'sd0;
            o_sin   <= 16'sd0;
            o_done  <= 1'b0;
        end else begin
            case (r_state)
                S_IDLE: begin
                    o_done <= 1'b0;
                    if (i_start) begin
                        r_iter  <= 4'd0;
                        r_state <= S_ROTATE;
                        // Fold |angle| > 90 deg 
                        if (w_angle_ext > HALF_PI) begin
                            r_x <= 18'sd0;
                            r_y <= K_FACTOR;
                            r_z <= w_angle_ext - HALF_PI;
                        end else if (w_angle_ext < -HALF_PI) begin
                            r_x <= 18'sd0;
                            r_y <= -K_FACTOR;
                            r_z <= w_angle_ext + HALF_PI;
                        end else begin
                            r_x <= K_FACTOR;
                            r_y <= 18'sd0;
                            r_z <= w_angle_ext;
                        end
                    end
                end

                S_ROTATE: begin
                    if (r_z >= 18'sd0) begin
                        r_x <= r_x - w_y_shift;
                        r_y <= r_y + w_x_shift;
                        r_z <= r_z - r_atan_lut;
                    end else begin
                        r_x <= r_x + w_y_shift;
                        r_y <= r_y - w_x_shift;
                        r_z <= r_z + r_atan_lut;
                    end

                    if (r_iter == LAST_ITER) r_state <= S_DONE;
                    else                     r_iter  <= r_iter + 4'd1;
                end

                S_DONE: begin
                    o_cos   <= sat16(r_x);
                    o_sin   <= sat16(r_y);
                    o_done  <= 1'b1;
                    r_state <= S_IDLE;
                end

                default: r_state <= S_IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
