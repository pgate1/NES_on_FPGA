
module Mapper_enable
(
	output wire [255:0] enable
);

	generate
		for(genvar i=0; i<256; i=i+1) begin : genmap
			case (i)
				0
				//, 1, 2
				//3, 
				//, 4
			//	, 25
				//, 73
				:
					assign enable[i] = 1'b1;
				default:
					assign enable[i] = 1'b0;
			endcase
		end
	endgenerate

endmodule
