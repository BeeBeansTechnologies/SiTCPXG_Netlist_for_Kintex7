//----------------------------------------------------------------------//
//
//	Copyright (c) 2020 BeeBeans Technologies All rights reserved
//
//		Module		: WRAP_SiTCPXG_XC7K_128K
//
//		Description	: Wrapping for 10GbE SiTCP Library
//
//		file		: WRAP_SiTCPXG_XC7K_128K.v
//
//		Note	: 
//
//		history	:
//			20200917	---------	Created by BBT
//			20201012	#20201014	Debaug for byte aline
//			20210901	#20210901	Changed the core of SiTCP library to SiTCPXG_XC7V_128K_V2
//
//----------------------------------------------------------------------//
module
	WRAP_SiTCPXG_XC7K_128K	#(
		parameter		RxBufferSize	= "LongLong"			// "Byte":8bit width ,"Word":16bit width ,"LongWord":32bit width , "LongLong":64bit width
	)(
		input	wire	[31:0]	REG_FPGA_VER				,	// in	: User logic Version(For example, the synthesized date)
		input	wire	[31:0]	REG_FPGA_ID					,	// in	: User logic ID (We recommend using the lower 4 bytes of the MAC address.)
		//		==== System I/F ====
		input	wire			FORCE_DEFAULTn				,	// in	: Force to set default values
		input	wire			XGMII_CLOCK					,	// in	: XGMII Clock 156.25MHz
		input	wire			RSTs						,	// in	: System reset (Sync.)
		//		==== XGMII I/F ====
		input	wire	[ 7:0]	XGMII_RXC					,	// in	: Rx control[7:0]
		input	wire	[63:0]	XGMII_RXD					,	// in	: Rx data[63:0]
		output	wire	[ 7:0]	XGMII_TXC					,	// out  : Control bits[7:0]
		output	wire	[63:0]	XGMII_TXD					, 	// out  : Data[63:0]
		//		==== 93C46 I/F ====
		output	wire			EEPROM_CS					,	// out	: Chip select
		output	wire			EEPROM_SK					,	// out	: Serial data clock
		output	wire			EEPROM_DI					,	// out	: Serial write data
		input	wire			EEPROM_DO					,	// in	: Serial read data
		//		==== User I/F ====
		output	wire			SiTCP_RESET_OUT				,	// out	: System reset for user's module
		//			--- RBCP ---
		output	wire			RBCP_ACT					,	// out	: Indicates that bus access is active.
		output	wire	[31:0]	RBCP_ADDR					,	// out	: Address[31:0]
		output	wire			RBCP_WE						,	// out	: Write enable
		output	wire	[ 7:0]	RBCP_WD						,	// out	: Data[7:0]
		output	wire			RBCP_RE						,	// out	: Read enable
		input	wire			RBCP_ACK					,	// in	: Access acknowledge
		input	wire	[ 7:0]	RBCP_RD						,	// in	: Read data[7:0]
		//			--- TCP ---
		input	wire			USER_SESSION_OPEN_REQ		,	// in	: Request for opening the new session
		output	wire			USER_SESSION_ESTABLISHED	,	// out	: Establish of a session 
		output	wire			USER_SESSION_CLOSE_REQ		,	// out	: Request for closing session.
		input	wire			USER_SESSION_CLOSE_ACK		,	// in	: Acknowledge for USER_SESSION_CLOSE_REQ.
		input	wire	[63:0]	USER_TX_D					,	// in	: Write data
		input	wire	[ 3:0]	USER_TX_B					,	// in	: Byte length of USER_TX_DATA(Set to 0 if not written)
		output	wire			USER_TX_AFULL				,	// out	: Request to stop TX
		input	wire	[15:0]	USER_RX_SIZE				,	// in	: Receive buffer size(byte) caution:Set a value of 4000 or more and (memory size-16) or less
		output	wire			USER_RX_CLR_ENB				,	// out	: Receive buffer Clear Enable
		input	wire			USER_RX_CLR_REQ				,	// in	: Receive buffer Clear Request
		input	wire	[15:0]	USER_RX_RADR				,	// in	: Receive buffer read address in bytes (unused upper bits are set to 0)
		output	wire	[15:0]	USER_RX_WADR				,	// out	: Receive buffer write address in bytes (lower 3 bits are not connected to memory)
		output	wire	[ 7:0]	USER_RX_WENB				,	// out	: Receive buffer byte write enable (big endian)
		output	wire	[63:0]	USER_RX_WDAT					// out	: Receive buffer write data (big endian)
	);

	wire			TIM_1US;
	wire			TIM_1MS;
	wire			TIM_1S;
	wire	[31:0]	MY_IP_ADDR;
	wire	[15:0]	MY_TCP_PORT;
	wire	[15:0]	MY_RBCP_PORT;
	wire	[47:0]	TCP_SERVER_MAC;
	wire	[31:0]	TCP_SERVER_ADDR;
	wire	[15:0]	TCP_SERVER_PORT;
	wire	[ 7:0]	SWAP_RX_WENB;
	wire	[64:0]	SWAP_RX_WDAT;

	generate
		if (RxBufferSize == "LongLong")	begin
			assign	USER_RX_WENB[ 7:0]	= SWAP_RX_WENB[ 7:0];
			assign	USER_RX_WDAT[63:0]	= SWAP_RX_WDAT[63:0];
		end else if (RxBufferSize == "LongWord") begin
			assign	USER_RX_WENB[ 3: 0]	= SWAP_RX_WENB[ 7: 4];
			assign	USER_RX_WDAT[31: 0]	= SWAP_RX_WDAT[63:32];
			assign	USER_RX_WENB[ 7: 4]	= SWAP_RX_WENB[ 3: 0];
			assign	USER_RX_WDAT[63:32]	= SWAP_RX_WDAT[31: 0];
		end else if (RxBufferSize == "Word") begin						// #20201012
			assign	USER_RX_WENB[ 1: 0]	= SWAP_RX_WENB[ 7: 6];
			assign	USER_RX_WDAT[15: 0]	= SWAP_RX_WDAT[63:48];
			assign	USER_RX_WENB[ 3: 2]	= SWAP_RX_WENB[ 5: 4];
			assign	USER_RX_WDAT[31:16]	= SWAP_RX_WDAT[47:32];
			assign	USER_RX_WENB[ 5: 4]	= SWAP_RX_WENB[ 3: 2];
			assign	USER_RX_WDAT[47:32]	= SWAP_RX_WDAT[31:16];
			assign	USER_RX_WENB[ 7: 6]	= SWAP_RX_WENB[ 1: 0];
			assign	USER_RX_WDAT[63:48]	= SWAP_RX_WDAT[15: 0];
		end else if (RxBufferSize == "Byte") begin						// #20201012
			assign	USER_RX_WENB[0]	= SWAP_RX_WENB[7];
			assign	USER_RX_WDAT[ 7: 0]	= SWAP_RX_WDAT[63:56];
			assign	USER_RX_WENB[1]	= SWAP_RX_WENB[6];
			assign	USER_RX_WDAT[15: 8]	= SWAP_RX_WDAT[55:48];
			assign	USER_RX_WENB[2]	= SWAP_RX_WENB[5];
			assign	USER_RX_WDAT[23:16]	= SWAP_RX_WDAT[47:40];
			assign	USER_RX_WENB[3]	= SWAP_RX_WENB[4];
			assign	USER_RX_WDAT[31:24]	= SWAP_RX_WDAT[39:32];
			assign	USER_RX_WENB[4]	= SWAP_RX_WENB[3];
			assign	USER_RX_WDAT[39:32]	= SWAP_RX_WDAT[31:24];
			assign	USER_RX_WENB[5]	= SWAP_RX_WENB[2];
			assign	USER_RX_WDAT[47:40]	= SWAP_RX_WDAT[23:16];
			assign	USER_RX_WENB[6]	= SWAP_RX_WENB[1];
			assign	USER_RX_WDAT[55:48]	= SWAP_RX_WDAT[15: 8];
			assign	USER_RX_WENB[7]	= SWAP_RX_WENB[0];
			assign	USER_RX_WDAT[63:56]	= SWAP_RX_WDAT[ 7: 0];
		end
	endgenerate

	TIMER_SiTCPXG	TIMER	(
		.CLK							(XGMII_CLOCK					),	// in	: 156.25MHz clock
		.RST							(RSTs							),	// in	: System reset
	// Intrrupts
		.TIM_1US						(TIM_1US						),	// out	: 1 us interval
		.TIM_1MS						(TIM_1MS						),	// out	: 1 ms interval
		.TIM_1S							(TIM_1S							)	// out	: 1 s interval
	);

	SiTCPXG_XC7K_128K_V2	SiTCP(		// #20210901
		.REG_FPGA_VER					(REG_FPGA_VER[31:0]				),	// in	: User logic Version(For example, the synthesized date)
		.REG_FPGA_ID					(REG_FPGA_ID[31:0]				),	// in	: User logic ID (We recommend using the lower 4 bytes of the MAC address.)
		//		==== System I/F ====
		.XGMII_CLOCK					(XGMII_CLOCK					),	// in	: XGMII clock
		.RSTs							(RSTs							),	// in	: System reset (Sync.)
		.TIM_1US						(TIM_1US						),	// in	: 1us interval pulse
		.TIM_1MS						(TIM_1MS						),	// in	: 1us interval pulse
		.TIM_1S							(TIM_1S							),	// in	: 1s	 interval pulse
		//		==== XGMII I/F ====
		.XGMII_RXC						(XGMII_RXC[ 7:0]				),	// in	: Rx control[7:0]
		.XGMII_RXD						(XGMII_RXD[63:0]				),	// in	: Rx data[63:0]
		.XGMII_TXC						(XGMII_TXC[ 7:0]				),	// out  : Control bits[7:0]
		.XGMII_TXD						(XGMII_TXD[63:0]				), 	// out  : Data[63:0]
		//		==== 93C46 I/F ====
		.EEPROM_CS						(EEPROM_CS						),	// out	: Chip select
		.EEPROM_SK						(EEPROM_SK						),	// out	: Serial data clock
		.EEPROM_DI						(EEPROM_DI						),	// out	: Serial write data
		.EEPROM_DO						(EEPROM_DO						),	// in	: Serial read data
		//		==== Configuration parameters ====
		.FORCE_DEFAULTn					(FORCE_DEFAULTn					),	// in	: Force to set default values
		.MY_MAC_ADDR					(								),	// out	: My IP MAC Address[47:0]
		.MY_IP_ADDR						(MY_IP_ADDR[31:0]				),	// in	: My IP address[31:0]
		.IP_ADDR_DEFAULT				(MY_IP_ADDR[31:0]				),	// out	: Default value for MY_IP_ADDR[31:0]
		.MY_TCP_PORT					(MY_TCP_PORT[15:0]				),	// in	: My TCP port[15:0]
		.TCP_PORT_DEFAULT				(MY_TCP_PORT[15:0]				),	// out	: Default value for my TCP MY_TCP_PORT[15:0]
		.MY_RBCP_PORT					(MY_RBCP_PORT[15:0]				),	// in	: My UDP RBCP-port[15:0]
		.RBCP_PORT_DEFAULT				(MY_RBCP_PORT[15:0]				),	// out	: Default value for my UDP RBCP-port #[15:0]
		.TCP_SERVER_MAC_IN  			(TCP_SERVER_MAC[47:0]			),	// in	: Client mode, Server MAC address[47:0]
		.TCP_SERVER_MAC_DEFAULT			(TCP_SERVER_MAC[47:0]			),	// out	: Default value for the server's MAC address
		.TCP_SERVER_ADDR_IN				(TCP_SERVER_ADDR[31:0]			),	// in	: Client mode, Server IP address[31:0]
		.TCP_SERVER_ADDR_DEFAULT		(TCP_SERVER_ADDR[31:0]			),	// out	: Default value for the server's IP address[31:0]
		.TCP_SERVER_PORT_IN				(TCP_SERVER_PORT[15:0]			),	// in	: Client mode, Server wating port#[15:0]
		.TCP_SERVER_PORT_DEFAULT		(TCP_SERVER_PORT[15:0]			),	// out	: Default value for the server port #[15:0]
		//		==== User I/F ====
		.SiTCP_RESET_OUT				(SiTCP_RESET_OUT				),	// out	: System reset for user's module
		//			--- RBCP ---
		.RBCP_ACT						(RBCP_ACT						),	// out	: Indicates that bus access is active.
		.RBCP_ADDR						(RBCP_ADDR[31:0]				),	// out	: Address[31:0]
		.RBCP_WE						(RBCP_WE						),	// out	: Write enable
		.RBCP_WD						(RBCP_WD[ 7:0]					),	// out	: Data[7:0]
		.RBCP_RE						(RBCP_RE						),	// out	: Read enable
		.RBCP_ACK						(RBCP_ACK						),	// in	: Access acknowledge
		.RBCP_RD						(RBCP_RD[ 7:0]					),	// in	: Read data[7:0]
		//			--- TCP ---
		.USER_SESSION_OPEN_REQ			(USER_SESSION_OPEN_REQ			),	// in	: Request for opening the new session
		.USER_SESSION_ESTABLISHED		(USER_SESSION_ESTABLISHED		),	// out	: Establish of a session 
		.USER_SESSION_CLOSE_REQ			(USER_SESSION_CLOSE_REQ			),	// out	: Request for closing session.
		.USER_SESSION_CLOSE_ACK			(USER_SESSION_CLOSE_ACK			),	// in	: Acknowledge for USER_SESSION_CLOSE_REQ.
		.USER_TX_D						(USER_TX_D[63:0]				),	// in	: Write data
		.USER_TX_B						(USER_TX_B[ 3:0]				),	// in	: Byte length of USER_TX_DATA(Set to 0 if not written)
		.USER_TX_AFULL					(USER_TX_AFULL					),	// out	: Request to stop TX
		.USER_RX_SIZE					(USER_RX_SIZE[15:0]				),	// in	: Receive buffer size(byte) caution:Set a value of 4000 or more and (memory size-16) or less
		.USER_RX_CLR_ENB				(USER_RX_CLR_ENB				),	// out	: Receive buffer Clear Enable
		.USER_RX_CLR_REQ				(USER_RX_CLR_REQ				),	// in	: Receive buffer Clear Request
		.USER_RX_RADR					(USER_RX_RADR[15:0]				),	// in	: Receive buffer read address in bytes (unused upper bits are set to 0)
		.USER_RX_WADR					(USER_RX_WADR[15:0]				),	// out	: Receive buffer write address in bytes (lower 3 bits are not connected to memory)
		.USER_RX_WENB					(SWAP_RX_WENB[ 7:0]				),	// out	: Receive buffer byte write enable (big endian)
		.USER_RX_WDAT					(SWAP_RX_WDAT[63:0]				)	// out	: Receive buffer write data (big endian)
	);

//------------------------------------------------------------------------------
endmodule
