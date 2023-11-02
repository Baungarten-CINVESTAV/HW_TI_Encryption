module fifo_8x56 (
    input wire clk,
    input wire reset,
    input wire wr_en,
    input wire rd_en,
    input wire [55:0] wr_data,
    output reg [55:0] rd_data,
    output reg fifo_empty
);
    reg [55:0] fifo [7:0];
    reg [2:0] wr_ptr = 0;
    reg [2:0] rd_ptr = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            if (wr_en)
                wr_ptr <= wr_ptr + 1;
            if (rd_en && !fifo_empty)
                rd_ptr <= rd_ptr + 1;
        end
    end

    always @(posedge clk) begin
        if (wr_en)
            fifo[wr_ptr] <= wr_data;
        if (rd_en && !fifo_empty)
            rd_data <= fifo[rd_ptr];
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            fifo_empty <= 1;
        else if (wr_en && !rd_en)
            fifo_empty <= 0;
        else if (!wr_en && rd_en)
            fifo_empty <= (rd_ptr == wr_ptr);
    end
endmodule
