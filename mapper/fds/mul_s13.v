
module mul_s13 (
	a, b, dout, con
);
	input signed [12:0] a, b;
	output signed [25:0] dout;
	input con;

	// -> 符号付き s13 x s13 = s26 ビット乗算
	assign dout = a * b;

endmodule
