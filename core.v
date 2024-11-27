
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
        .D(input_sram_din),
        .Q(input_sram_dout)
    );

    // Accumulation SRAM
    sram_input acc_sram (
        .CLK(clk),
        .A(acc_sram_addr),
        .CEN(acc_sram_cen),
        .WEN(acc_sram_wen),
        .D(acc_sram_din),
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

    // Address and control logic generation 
    address_generator addr_gen (
        .clk(clk),
        .reset(reset),
        .inst(inst),
        .input_sram_addr(input_sram_addr),
        .input_sram_cen(input_sram_cen),
        .input_sram_wen(input_sram_wen),
        .input_sram_din(input_sram_din),
        .acc_sram_addr(acc_sram_addr),
        .acc_sram_cen(acc_sram_cen),
        .acc_sram_wen(acc_sram_wen),
        .acc_sram_din(acc_sram_din)
    );

    // OFIFO valid generation
    reg ofifo_valid_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            ofifo_valid_reg <= 1'b0;
        else
            // Example condition - adjust as needed
            ofifo_valid_reg <= (inst[6] == 1'b1); // OFIFO read enable
    end
    assign ofifo_valid = ofifo_valid_reg;
endmodule

// Modified address generator
module address_generator (
    input clk,
    input reset,
    input [33:0] inst,
    
    output reg [10:0] input_sram_addr,
    output reg input_sram_cen,
    output reg input_sram_wen,
    output reg [31:0] input_sram_din,
    
    output reg [10:0] acc_sram_addr,
    output reg acc_sram_cen,
    output reg acc_sram_wen,
    output reg [31:0] acc_sram_din
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset addresses and control signals
            input_sram_addr <= 0;
            acc_sram_addr <= 0;
            
            // Disable SRAMs initially
            input_sram_cen <= 1;
            input_sram_wen <= 1;
            acc_sram_cen <= 1;
            acc_sram_wen <= 1;
            
            // Clear input and accumulation data
            input_sram_din <= 32'b0;
            acc_sram_din <= 32'b0;
        end else begin
            // Input SRAM control
            // inst[4] - read, inst[5] - write
            input_sram_cen <= ~(inst[4] | inst[5]);
            input_sram_wen <= ~inst[5]; // Active low write enable
            
            if (inst[4]) // Read
                input_sram_addr <= input_sram_addr + 1;
            
            if (inst[5]) // Write
                input_sram_addr <= input_sram_addr + 1;
            
            // Accumulator SRAM control
            // inst[3] - read, inst[2] - write
            acc_sram_cen <= ~(inst[3] | inst[2]);
            acc_sram_wen <= ~inst[2]; // Active low write enable
            
            if (inst[3]) // Read
                acc_sram_addr <= acc_sram_addr + 1;
            
            if (inst[2]) // Write
                acc_sram_addr <= acc_sram_addr + 1;
        end
    end
endmodule
