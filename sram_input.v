module sram_input (
    input CLK,
    input [31:0] D,      // Input data
    output [31:0] Q,     // Output data
    input CEN,           // Chip Enable (active low)
    input WEN,           // Write Enable (active low)
    input [10:0] A       // Address
);
    parameter num = 2048;
    reg [31:0] memory [num-1:0];
    reg [10:0] add_q;

    assign Q = memory[add_q];

    always @ (posedge CLK) begin
        if (!CEN) begin
            if (WEN) // Read operation
                add_q <= A;
            else     // Write operation
                memory[A] <= D;
        end
    end
endmodule