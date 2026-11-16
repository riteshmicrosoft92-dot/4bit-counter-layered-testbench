// 4-bit synchronous up-counter with active-high synchronous reset.
module counter (
    input logic clk,
    input logic rst,
    input logic enable,
    output logic [3:0] count
);
    always_ff @(posedge clk) begin
        if (rst) count <= 4'b0000;
        else if (enable) count <= count + 4'd1;
    end
endmodule
