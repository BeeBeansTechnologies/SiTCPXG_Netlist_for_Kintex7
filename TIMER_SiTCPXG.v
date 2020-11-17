//----------------------------------------------------------------------//
//
//	Copyright (c) 2020 BeeBeans Technologies All rights reserved
//
//		Module		: SiTCPXG_TIMER
//
//		Description	: Timer for 10GbE SiTCP Library
//
//		file		: SiTCPXG_TIMER.v
//
//		Note	: Clock frequency is 156.25MHz
//
//		history	:
//			20200917	---------	Created by BBT (Referenced to SiTCP's TIMER module)
//
//----------------------------------------------------------------------//
module
	TIMER_SiTCPXG	(
		input	wire			CLK					,	// in	: System clock
		input	wire			RST					,	// in	: System reset
		output	wire			TIM_1US				,	// out	: 1 us interval
		output	wire			TIM_1MS				,	// out	: 1 ms interval
		output	wire			TIM_1S					// out	: 1 s interval
	);

	reg				pulse1us			;
	reg				pulse1ms			;
	reg				pulse1s				;
	reg				usCry				;
	reg		[ 7:0]	usTim				;
	reg		[ 2:0]	usAdj				;
	reg		[10:0]	msTim				;
	reg		[10:0]	sTim				;



//------------------------------------------------------------------------------
//	Timer
//------------------------------------------------------------------------------

	always@ (posedge CLK) begin
		if(RST)begin
			{usCry,usTim[7:0]}	<= 9'd0;
			usAdj[2:0]			<= 3'd2;
		end else begin
			{usCry,usTim[7:0]}	<= usCry?		{1'b0,(usAdj[2]?	8'd155:		8'd154)}:	({1'b0,usTim[7:0]} - 9'd1);
			if (usCry) begin
				usAdj[2:0]		<= usAdj[2]?	3'd2:										(usAdj[2:0] - 3'd1);
			end
		end
	end

	always@ (posedge CLK) begin
		if(RST)begin
			msTim[10:0]	<= 11'd0;
			sTim[10:0]	<= 11'd0;
		end else begin
			if(usCry)begin
				msTim[10:0]	<= (msTim[10]	? 11'd998 : msTim[10:0] - 11'd1);
			end
			if(usCry & msTim[10])begin
				sTim[10:0]	<= (sTim[10]	? 11'd998 : sTim[10:0] - 11'd1);
			end
		end
	end

	always@ (posedge CLK) begin
		pulse1us	<= usCry;
		pulse1ms	<= usCry & msTim[10];
		pulse1s		<= usCry & msTim[10] & sTim[10];
	end

	assign	TIM_1US	= pulse1us;
	assign	TIM_1MS	= pulse1ms;
	assign	TIM_1S	= pulse1s;

//------------------------------------------------------------------------------
endmodule
