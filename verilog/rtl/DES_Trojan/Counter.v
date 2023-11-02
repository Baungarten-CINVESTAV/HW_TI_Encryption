module Counter (
  input clk,       // Clock input
  input reset,     // Reset input
  input init,      // Initialize counter
  output reg finish, // Finish flag
  output reg [4:0] count, // 4-bit counter output
  input [63:0] i_Data,
  output reg [63:0] o_Data
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      count <= 5'b10000; // Reset the counter to 0
      finish <= 1'b0; // Reset the finish flag
		o_Data <= 64'b0;
    end else if (init) begin
      count <= 5'b0; // Initialize the counter to 0
      finish <= 1'b0; // Reset the finish flag
		o_Data <= 64'b0;
    end else if (count == 5'b1111) begin
      // When the counter reaches 15 (1111 in binary), set finish flag
      		finish <= 1'b1;
		o_Data<=i_Data;
		count <= count + 1'b1;
	 end else if (count == 5'b10000) begin
	   finish <= finish;
		o_Data<=o_Data;
		count <= count;
    end else begin
      // Increment the counter
      count <= count + 1'b1;
      finish <= 1'b0; // Reset the finish flag
		o_Data <= o_Data;
    end
  end

endmodule
