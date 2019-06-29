
module mul_6 (
	a, b, dout, con
);
	input [5:0] a, b; // unsigned
	output [11:0] dout; // unsigned
	input con;

	// -> •„†‚È‚µ 6 x 6 = 12 ƒrƒbƒgæZ
	assign dout = a * b;

endmodule
