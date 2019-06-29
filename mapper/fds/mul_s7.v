
module mul_s7 (
	a, b, dout, con
);
	input signed [6:0] a, b;
	output signed [13:0] dout;
	input con;

	// -> 符号付き s7 x s7 = s14 ビット乗算
	assign dout = a * b;

endmodule
