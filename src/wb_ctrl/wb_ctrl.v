//------------------------------------------------------------------------------
// wb_ctrl.v
//------------------------------------------------------------------------------

module wb_ctrl(
	// wishbone master
	input           wb_rst_i,
	input           wb_clk_i,
	output  [11:0]  wb_adr_o,
	input   [31:0]  wb_dat_i,
	output  [31:0]  wb_dat_o,
	output          wb_we_o,
	output  [3:0]   wb_sel_o,
	output          wb_stb_o,
	input           wb_ack_i,
	output          wb_cyc_o
);

	//  4bit  12bit      32bit
	// {inst,  addr, immidiate}
	parameter INST_WAIT       = 4'd0;
	parameter INST_READ       = 4'd1;
	parameter INST_WRITE_IMD  = 4'd2;
	parameter WAIT_INFTY = 32'hFFFF_FFFF;

	wire    [47:0]  curr_inst;
	wire    [3:0]   curr_inst_type;
	wire    [11:0]  curr_inst_addr;
	wire    [31:0]  curr_inst_value;
	wire            end_curr_inst;

	reg     [7:0]   prog_count_r;

	reg             start_curr_inst_r;

	reg     [31:0]  wait_count_r;

	reg     [11:0]  address_r;
	reg     [31:0]  data_r;
	reg             we_r;
	reg             stb_r;
	reg             cyc_r;

	// output port connection
	assign wb_adr_o = address_r;
	assign wb_dat_o = data_r;
	assign wb_sel_o = 4'b1111;
	assign wb_we_o  = we_r;
	assign wb_stb_o = stb_r;
	assign wb_cyc_o = cyc_r;

	// instruction memory
	function [47:0] inst_mem_f;
		input [7:0] prog_count_arg;
		case (prog_count_r)
			8'd0    : inst_mem_f = {      INST_WAIT, 12'h000,    WAIT_INFTY};
			8'd1    : inst_mem_f = { INST_WRITE_IMD, 12'h000, 32'h0000_0002};
			8'd2    : inst_mem_f = {      INST_READ, 12'h100,         32'b0};
			default : inst_mem_f = {      INST_WAIT, 12'h000,    WAIT_INFTY};
		endcase
	endfunction

	// indicator of current instruction
	assign curr_inst       = inst_mem_f(prog_count_r);
	assign curr_inst_type  = curr_inst[47:44];
	assign curr_inst_addr  = curr_inst[43:32];
	assign curr_inst_value = curr_inst[31:0];

	// end_curr_inst should be asserted if current instruction will be completed on this clock cycle
	function end_curr_inst_f;
		input  [3:0] curr_inst_type_arg;
		input        start_curr_inst_arg;
		input [31:0] wait_count_arg;
		input        wb_ack_i_arg;
		case (curr_inst_type_arg)
			INST_WAIT       : end_curr_inst_f = ((|wait_count_arg) == 1'b0);
			INST_READ       : end_curr_inst_f = ~start_curr_inst_arg & wb_ack_i_arg;
			INST_WRITE_IMD  : end_curr_inst_f = ~start_curr_inst_arg & wb_ack_i_arg;
			default         : end_curr_inst_f = 1'b0;
		endcase
	endfunction
	assign end_curr_inst = end_curr_inst_f(curr_inst_type, start_curr_inst_r, wait_count_r, wb_ack_i);

	// program counter
	always @ (posedge wb_clk_i) begin
		if (wb_rst_i) begin
			prog_count_r <= 8'd0;
		end else if (end_curr_inst == 1'b1) begin
			prog_count_r <= prog_count_r + 8'd1;
		end else begin
			prog_count_r <= prog_count_r;
		end
	end

	// instruction start flag asserted just first 1 cycle of executing current instruction
	always @ (posedge wb_clk_i) begin
		if (wb_rst_i) begin
			start_curr_inst_r <= 1'b1;
		end else if (end_curr_inst == 1'b1) begin
			start_curr_inst_r <= 1'b1;
		end else begin
			start_curr_inst_r <= 1'b0;
		end
	end
	
	// instruction start flag drives loading address
	always @ (posedge wb_clk_i) begin
		if (wb_rst_i) begin
			address_r <= 12'd0;
		end else if (start_curr_inst_r == 1'b1) begin
			address_r <= curr_inst_addr;
		end else begin
			address_r <= address_r;
		end
	end

	// data register
	function [31:0] data_f;
		input [3:0]  curr_inst_type_arg;
		input [31:0] curr_data_arg;
		input [31:0] curr_inst_value_arg;
		input [31:0] wb_dat_i_arg;
		input        wb_ack_i_arg;
		input        start_curr_inst_arg;
		case (curr_inst_type_arg)
			INST_READ : begin
				if (wb_ack_i_arg) begin
					data_f = wb_dat_i_arg;
				end else begin
					data_f = curr_data_arg;
				end
			end
			INST_WRITE_IMD : begin
				if (start_curr_inst_arg) begin
					data_f = curr_inst_value_arg;
				end else begin
					data_f = curr_data_arg;
				end
			end
			default : begin
				data_f = curr_data_arg;
			end
		endcase
	endfunction
	always @ (posedge wb_clk_i) begin
		if (wb_rst_i) begin
			data_r <= 32'd0;
		end else begin
			data_r <= data_f(curr_inst_type,
			                 data_r,
			                 curr_inst_value,
			                 wb_dat_i,
			                 wb_ack_i,
			                 start_curr_inst_r);
		end
	end

	// control for read enable flag
	always @ (posedge wb_clk_i) begin
		if (wb_rst_i) begin
			stb_r <= 1'b0;
		end else if (start_curr_inst_r && curr_inst_type == INST_READ) begin
			stb_r <= 1'b1;
		end else begin
			stb_r <= 1'b0;
		end
	end

	// control for write enable flag
	always @ (posedge wb_clk_i) begin
		if (wb_rst_i) begin
			we_r <= 1'b0;
		end else if (end_curr_inst) begin
			we_r <= 1'b0;
		end else if (start_curr_inst_r && curr_inst_type == INST_WRITE_IMD) begin
			we_r <= 1'b1;
		end else begin
			we_r <= we_r;
		end
	end

	// counter for waiting cycles left
	always @ (posedge wb_clk_i) begin
		if (wb_rst_i) begin
			wait_count_r <= WAIT_INFTY;
		end else if (start_curr_inst_r == 1'b1 && curr_inst_type == INST_WAIT) begin
			wait_count_r <= curr_inst_value;
		end else if ((&wait_count_r) == 1'b1) begin
			wait_count_r <= wait_count_r;
		end else begin
			wait_count_r <= wait_count_r - 32'd1;
		end
	end
endmodule
