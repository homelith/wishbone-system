module top
(
	//// CLK & PUSH SW ////
	input           ARST_N,
	input           XTAL_IN,
	input           PSW,

	//// AE-FT234X ////
	input           UART_RX,
	output          UART_TX,

	//// LED array for dynamic driving ////
	output  [7:0]   MATRIX_COL_SEG7_ELEM,
	output  [7:0]   MATRIX_ROW,
	output          SEG7_CA,

	//// 8x in-line dip switch
	input   [7:0]   DIPSW,

	//// HD44780 compatible character LCD ////
	output  [3:0]   CHARLCD_DB, // DB4, 5, 6, 7
	output          CHARLCD_E,
	output          CHARLCD_RW,
	output          CHARLCD_RS,

	//// On-board LED ////
	output  [5:0]   LED
);

	assign CHARLCD_DB = 4'd0;
	assign CHARLCD_E = 1'b0;
	assign CHARLCD_RW = 1'b0;
	assign CHARLCD_RS = 1'b0;

	// using internal OSC
	//Gowin_OSC chip_osc(
	//	.oscout(oscout_o) //output oscout
	//);

	// PLL for driving LCD
	//Gowin_rPLL chip_pll(
	//	.clkout(CLK_SYS),  // output clkout    // 200M
	//	.clkoutd(CLK_PIX), // output clkoutd   // 33.33M
	//	.clkin(XTAL_IN)    // input clkin
	//);

	// LED dynamic drive lookup
	function [8:0] led_row_f;
		input [3:0] led_row_arg;
		begin
		case (led_row_arg)
			4'd0: led_row_f = 9'b100000000;
			4'd1: led_row_f = 9'b010000000;
			4'd2: led_row_f = 9'b001000000;
			4'd3: led_row_f = 9'b000100000;
			4'd4: led_row_f = 9'b000010000;
			4'd5: led_row_f = 9'b000001000;
			4'd6: led_row_f = 9'b000000100;
			4'd7: led_row_f = 9'b000000010;
			4'd8: led_row_f = 9'b000000001;
		endcase
		end
	endfunction

	function [7:0] led_col_f;
		input [3:0] led_row_arg;
		input [7:0] led_col_0_arg;
		input [7:0] led_col_1_arg;
		input [7:0] led_col_2_arg;
		input [7:0] led_col_3_arg;
		input [7:0] led_col_4_arg;
		input [7:0] led_col_5_arg;
		input [7:0] led_col_6_arg;
		input [7:0] led_col_7_arg;
		input [7:0] led_col_8_arg;
		begin
		case (led_row_arg)
			4'd0 : led_col_f = led_col_0_arg;
			4'd1 : led_col_f = led_col_1_arg;
			4'd2 : led_col_f = led_col_2_arg;
			4'd3 : led_col_f = led_col_3_arg;
			4'd4 : led_col_f = led_col_4_arg;
			4'd5 : led_col_f = led_col_5_arg;
			4'd6 : led_col_f = led_col_6_arg;
			4'd7 : led_col_f = led_col_7_arg;
			4'd8 : led_col_f = led_col_8_arg;
		endcase
		end
	endfunction

	// drive LED
	reg     [31:0]  ledcnt_r;
	reg     [5:0]   led_r;
	assign LED = led_r;

	always @ (posedge XTAL_IN or negedge ARST_N) begin
		if (!ARST_N) begin
			ledcnt_r <= 24'd0;
		end else if (ledcnt_r < 24'd400_0000) begin
			ledcnt_r <= ledcnt_r + 1;
		end else begin
			ledcnt_r <= 24'd0;
		end
	end

	always @ (posedge XTAL_IN or negedge ARST_N) begin
		if (!ARST_N) begin
			led_r <= 6'b111110;
		end else if (ledcnt_r == 24'd400_0000) begin
			led_r[5:0] <= {led_r[4:0],led_r[5]};
		end else begin
			led_r <= led_r;
		end
	end

	reg [13:0] dyn_refresh_cnt_r;
	reg [21:0] row_slide_cnt_r;
	reg [3:0] led_row_r;
	reg [7:0] led_col_0_r;
	reg [7:0] led_col_1_r;
	reg [7:0] led_col_2_r;
	reg [7:0] led_col_3_r;
	reg [7:0] led_col_4_r;
	reg [7:0] led_col_5_r;
	reg [7:0] led_col_6_r;
	reg [7:0] led_col_7_r;
	reg [7:0] led_col_8_r;

	assign {SEG7_CA, MATRIX_ROW} = led_row_f(led_row_r);
	assign MATRIX_COL_SEG7_ELEM = led_col_f(led_row_r,
	                                        led_col_0_r,
	                                        led_col_1_r,
	                                        led_col_2_r,
	                                        led_col_3_r,
	                                        led_col_4_r,
	                                        led_col_5_r,
	                                        led_col_6_r,
	                                        led_col_7_r,
	                                        led_col_8_r);

	always @ (posedge XTAL_IN) begin
		dyn_refresh_cnt_r <= dyn_refresh_cnt_r + 14'd1;
	end
	always @ (posedge XTAL_IN) begin
		row_slide_cnt_r <= row_slide_cnt_r + 22'd1;
	end

	always @ (posedge XTAL_IN or negedge ARST_N) begin
		if (! ARST_N) begin
			led_col_0_r <= 8'b00000000;
			led_col_1_r <= 8'b00011000;
			led_col_2_r <= 8'b00100100;
			led_col_3_r <= 8'b01000010;
			led_col_4_r <= 8'b10000001;
			led_col_5_r <= 8'b10000001;
			led_col_6_r <= 8'b01000010;
			led_col_7_r <= 8'b00100100;
			led_col_8_r <= 8'b00011000;
		end else if (row_slide_cnt_r == 22'd0) begin
			led_col_0_r <= ~DIPSW;
			led_col_1_r <= led_col_2_r;
			led_col_2_r <= led_col_3_r;
			led_col_3_r <= led_col_4_r;
			led_col_4_r <= led_col_5_r;
			led_col_5_r <= led_col_6_r;
			led_col_6_r <= led_col_7_r;
			led_col_7_r <= led_col_8_r;
			led_col_8_r <= led_col_1_r;
		end else begin
			led_col_0_r <= led_col_0_r;
			led_col_1_r <= led_col_1_r;
			led_col_2_r <= led_col_2_r;
			led_col_3_r <= led_col_3_r;
			led_col_4_r <= led_col_4_r;
			led_col_5_r <= led_col_5_r;
			led_col_6_r <= led_col_6_r;
			led_col_7_r <= led_col_7_r;
			led_col_8_r <= led_col_8_r;
		end
	end

	always @ (posedge XTAL_IN or negedge ARST_N) begin
		if (! ARST_N) begin
			led_row_r <= 4'd0;
		end else if (dyn_refresh_cnt_r == 14'd0) begin
			if (led_row_r == 4'd8) begin
				led_row_r <= 4'd0;
			end else begin
				led_row_r <= led_row_r + 4'd1;
			end
		end else begin
			led_row_r <= led_row_r;
		end
	end
endmodule

