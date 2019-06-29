
module mul_4 (
	a, b, dout, con
);
	input [3:0] a, b; // unsigned
	output [7:0] dout; // unsigned
	input con;

	// -> •„†‚È‚µ 4 x 4 = 8 ƒrƒbƒgæZ
	assign dout = a * b;

endmodule
