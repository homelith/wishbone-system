//------------------------------------------------------------------------------
// tb.v
//------------------------------------------------------------------------------
`timescale 10 ps / 1 ps

module tb;
	wire    arst_n;
	wire    clk50;
	wire    clk125;
	wire    clk50_srst_n;
	wire    clk125_srst_n;
	wire    gpio_out;

	// clock generator
	clk_gen clk_gen_inst(
		.arst_n       (arst_n),
		.clk50        (clk50),
		.clk125       (clk125),
		.clk50_srst_n (clk50_srst_n),
		.clk125_srst_n(clk125_srst_n)
	);

	// dut
	wb_gpio dut(
		// WISHBONE Interface
		.wb_clk_i (clk50),
		.wb_rst_i (! clk50_srst_n),
		.wb_cyc_i (),
		.wb_adr_i (),
		.wb_dat_i (),
		.wb_sel_i (),
		.wb_we_i  (),
		.wb_stb_i (),
		.wb_dat_o (),
		.wb_ack_o (),
		.wb_err_o (),
		.wb_inta_o(),

		// External GPIO Interface
		.gpio_i   (),
		.gpio_o   (),
		.gpio_oe_o()
	);

	// limiting simulation time
	integer k;
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars(1, dut);
		for ( k = 0 ; k < 10000 ; k = k + 1 ) begin
			@ ( posedge clk50 );
		end
		$finish;
	end

	// simulation scenario
	initial begin
		@ (negedge arst_n);
		@ (posedge arst_n);
	end
endmodule

module clk_gen(
	output arst_n,
	output clk50,
	output clk125,
	output clk50_srst_n,
	output clk125_srst_n
);
	reg arst_n_r;
	reg clk50_r;
	reg clk125_r;
	reg clk50_srst_n_r;
	reg clk125_srst_n_r;
	assign arst_n = arst_n_r;
	assign clk50 = clk50_r;
	assign clk125 = clk125_r;
	assign clk50_srst_n = clk50_srst_n_r;
	assign clk125_srst_n = clk125_srst_n_r;
	initial begin
		arst_n_r = 1'b1;
		#(1.24 * 2000);
		arst_n_r = 1'b0;
		#(18.9 * 2000);
		arst_n_r = 1'b1;
	end
	always begin
		clk50_r = 0;
		#(2000/2);
		clk50_r = 1;
		#(2000/2);
	end
	always begin
		clk125_r = 0;
		#(800/2);
		clk125_r = 1;
		#(800/2);
	end
	always @ (posedge clk50_r or negedge arst_n_r) begin
		if (! arst_n_r) begin
			clk50_srst_n_r <= 1'b0;
		end else begin
			clk50_srst_n_r <= 1'b1;
		end
	end
	always @ (posedge clk125_r or negedge arst_n_r) begin
		if (! arst_n_r) begin
			clk125_srst_n_r <= 1'b0;
		end else begin
			clk125_srst_n_r <= 1'b1;
		end
	end
endmodule
