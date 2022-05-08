//------------------------------------------------------------------------------
// tb.v
//------------------------------------------------------------------------------
`timescale 1 ns / 100 ps

module tb;
	wire            arst_n;
	wire            clk50;
	wire            clk125;
	wire            clk50_srst_n;
	wire            clk125_srst_n;

	wire    [11:0]  wb_adr_dut2tb;
	wire    [31:0]  wb_dat_tb2dut;
	wire    [31:0]  wb_dat_dut2tb;
	wire            wb_we_dut2tb;
	wire    [3:0]   wb_sel_dut2tb;
	wire            wb_stb_dut2tb;
	wire            wb_ack_tb2dut;
	wire            wb_cyc_dut2tb;

	reg     [31:0]  wb_dat_tb2dut_r;
	reg             wb_ack_tb2dut_r;
	assign wb_dat_tb2dut = wb_dat_tb2dut_r;
	assign wb_ack_tb2dut = wb_ack_tb2dut_r;

	// clock generator
	clk_gen clk_gen_inst(
		.arst_n       (arst_n),
		.clk50        (clk50),
		.clk125       (clk125),
		.clk50_srst_n (clk50_srst_n),
		.clk125_srst_n(clk125_srst_n)
	);

	// dut
	wb_ctrl dut(
		.wb_rst_i (arst_n),
		.wb_clk_i (clk50),
		.wb_adr_o (wb_adr_dut2tb),
		.wb_dat_i (wb_dat_tb2dut),
		.wb_dat_o (wb_dat_dut2tb),
		.wb_we_o  (wb_we_dut2tb),
		.wb_sel_o (wb_sel_dut2tb),
		.wb_stb_o (wb_stb_dut2tb),
		.wb_ack_i (wb_ack_tb2dut),
		.wb_cyc_o (wb_cyc_dut2tb)
	);

	// simulation scenario
	integer i;
	initial begin
		@ (negedge arst_n);
		wb_dat_tb2dut_r = 32'd0;
		wb_ack_tb2dut_r = 1'b0;
		@ (posedge arst_n);

		for ( i = 0 ; i < 30 ; i = i + 1 ) begin
			@ ( posedge clk50 );
		end

		@ (posedge clk50);

		while (1'b1) begin
			if (wb_stb_dut2tb | wb_we_dut2tb) begin
				@ (posedge clk50);
				@ (posedge clk50);
				@ (posedge clk50);
				wb_ack_tb2dut_r = 1'b1;
				@ (posedge clk50);
				wb_ack_tb2dut_r = 1'b0;
			end
			@ (posedge clk50);
		end
	end

	// limiting simulation time
	integer k;
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars(1, dut);
		for ( k = 0 ; k < 1000 ; k = k + 1 ) begin
			@ ( posedge clk50 );
		end
		$finish;
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
