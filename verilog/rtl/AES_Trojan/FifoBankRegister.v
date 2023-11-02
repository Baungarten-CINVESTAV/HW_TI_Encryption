module FifoBankRegister(
  input wire clk,      // Clock input
  input wire reset,    // Reset input
  input wire write_en, // Write enable input
  input wire read_en,  // Read enable input
  input wire [127:0] data_in, // Data input
  output reg [127:0] data_out // Data output
);

  // Parameters
  parameter DEPTH = 10; // Depth of the FIFO

  // Internal signals
  reg [127:0] bank [0:DEPTH-1];
  reg [3:0] write_ptr;
  reg [3:0] read_ptr;
  wire empty = (write_ptr == read_ptr);
  wire full = ((write_ptr + 1) % DEPTH == read_ptr);

  // Procedural block for read and write operations
  always @(posedge clk or negedge reset) begin
    if (!reset) begin
      write_ptr <= 0;
      read_ptr <= 0;
    end else begin
      if (write_en && !full) begin
        bank[write_ptr] <= data_in;
        write_ptr <= (write_ptr + 1) % DEPTH;
      end
      if (read_en && !empty) begin
        data_out <= bank[read_ptr];
        read_ptr <= (read_ptr + 1) % DEPTH;
      end
    end
  end

endmodule
