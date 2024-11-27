
module core #(
    parameter row = 8,
    parameter col = 8,
    parameter psum_bw = 16,
    parameter bw = 4
)(
    input clk,
    input reset,
    input [33:0] inst,
    
    // New ports from testbench
    output ofifo_valid,
    input [31:0] D_xmem,
    output [psum_bw*col-1:0] sfp_out
);

    // Input SRAM signals (for weights and activations)
    wire [10:0] input_sram_addr;
    wire input_sram_cen, input_sram_wen;
    wire [31:0] input_sram_din, input_sram_dout;

    // Accumulation SRAM signals
    wire [10:0] acc_sram_addr;
    wire acc_sram_cen, acc_sram_wen;
    wire [31:0] acc_sram_din, acc_sram_dout;

    // Input SRAM (for weights and activations)
    sram_input input_sram (
        .CLK(clk),
        .A(input_sram_addr),
        .CEN(input_sram_cen),
        .WEN(input_sram_wen),
        .D(D_xmem),
        .Q(input_sram_dout)
    );

    // Accumulation SRAM
    sram_input acc_sram (
        .CLK(clk),
        .A(acc_sram_addr),
        .CEN(acc_sram_cen),
        .WEN(acc_sram_wen),
        .D(data_out),
        .Q(acc_sram_dout)
    );

    // Corelet
    wire [psum_bw*col-1:0] data_out;
    corelet #(
        .row(row),
        .col(col),
        .psum_bw(psum_bw),
        .bw(bw)
    ) corelet_inst (
        .clk(clk),
        .reset(reset),
        .inst(inst),
        .data_in(input_sram_dout[bw*row-1:0]),
        .data_in_acc(acc_sram_dout[psum_bw*col-1:0]),
        .data_out(data_out),
        .sfp_data_out(sfp_out)
    );

  
