
module mul_12 (
	a, b, dout, con
);
	input [11:0] a, b; // unsigned
	output [21:0] dout; // unsigned
	input con;

	// -> •„†‚È‚µ 12 x 12 = 24 ƒrƒbƒgæZ
	assign dout = a * b;

endmodule
