module wb_gpio(
	// WISHBONE Interface
	input           wb_clk_i,
	input           wb_rst_i,
	input           wb_cyc_i,
	input           wb_adr_i,
	input   [31:0]  wb_dat_i,
	input   [3:0]   wb_sel_i,
	input           wb_we_i,
	input           wb_stb_i,
	output  [31:0]  wb_dat_o,
	output          wb_ack_o,
	output          wb_err_o,
	output          wb_inta_o,

	// External GPIO Interface
	input   [31:0]  gpio_i,
	output  [31:0]  gpio_o,
	output          gpio_oe_o
);

	reg [31:0] gpio_o_r;
	assign gpio_o = gpio_o_r;
	always @ (posedge wb_clk_i) begin
		if (wb_rst_i) begin
			gpio_o_r <= 32'b0;
		end else begin
			gpio_o_r <= 32'b0;
		end
	end
endmodule
