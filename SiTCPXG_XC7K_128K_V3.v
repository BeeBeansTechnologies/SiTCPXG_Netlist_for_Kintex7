//----------------------------------------------------------------------//
//
//	Copyright (c) 2020 BeeBeans Technologies All rights reserved
//
//		Module		: SiTCPXG_XC7K_128K_V3
//
//		Description	: 10GbE SiTCP Library for Kintex7(Standerd)
//
//		file		: SiTCPXG_XC7K_128K_V3.v
//
//		Note	: 
//
//		history	:
//			The original source was developed by Dr. Uchida(2017)
//			20200917					---------	Created by BBT
//			20201014	V1	Rev 1.2		---------	Created by BBT
//			20211006	V2	Rev 1.3		---------	Improving IFG during reception
//													Improving IFG during transmission
//													Fixed a bug caused when transmission is interrupted due to RST reception
//			20221027	V3	Rev 1.4		---------	Loopback bug fix
//										---------	Added circuit to send data in acknowledgment
//										---------	Disable Nagle Algorithm at End of Session
//
//----------------------------------------------------------------------//

module
	SiTCPXG_XC7K_128K_V3	(
		input	wire	[31:0]	REG_FPGA_VER					,	// in	: User logic Version(For example, the synthesized date)
		input	wire	[31:0]	REG_FPGA_ID						,	// in	: User logic ID (We recommend using the lower 4 bytes of the MAC address.)
		//		==== System I/F ====
		input	wire			XGMII_CLOCK						,	// in	: XGMII clock
		input	wire			RSTs							,	// in	: System reset (Sync.)
		input	wire			TIM_1US							,	// in	: 1us interval pulse
		input	wire			TIM_1MS							,	// in	: 1us interval pulse
		input	wire			TIM_1S							,	// in	: 1s	 interval pulse
		//		==== XGMII I/F ====
		input	wire	[ 7:0]	XGMII_RXC						,	// in	: Rx control[7:0]
		input	wire	[63:0]	XGMII_RXD						,	// in	: Rx data[63:0]
		output	wire	[ 7:0]	XGMII_TXC						,	// out  : Control bits[7:0]
		output	wire	[63:0]	XGMII_TXD						, 	// out  : Data[63:0]
		//		==== 93C46 I/F ====
		output	wire			EEPROM_CS						,	// out	: Chip select
		output	wire			EEPROM_SK						,	// out	: Serial data clock
		output	wire			EEPROM_DI						,	// out	: Serial write data
		input	wire			EEPROM_DO						,	// in	: Serial read data
		//		==== Configuration parameters ====
		input	wire			FORCE_DEFAULTn					,	// in	: Force to set default values
		output	wire	[47:0]	MY_MAC_ADDR						,	// out	: My IP MAC Address[47:0]
		input	wire	[31:0]	MY_IP_ADDR						,	// in	: My IP address[31:0]
		output	wire	[31:0]	IP_ADDR_DEFAULT					,	// out	: Default value for MY_IP_ADDR[31:0]
		input	wire	[15:0]	MY_TCP_PORT						,	// in	: My TCP port[15:0]
		output	wire	[15:0]	TCP_PORT_DEFAULT				,	// out	: Default value for my TCP MY_TCP_PORT[15:0]
		input	wire	[15:0]	MY_RBCP_PORT					,	// in	: My UDP RBCP-port[15:0]
		output	wire	[15:0]	RBCP_PORT_DEFAULT				,	// out	: Default value for my UDP RBCP-port #[15:0]
		input	wire	[47:0]	TCP_SERVER_MAC_IN  				,	// in	: Client mode, Server MAC address[47:0]
		output	wire	[47:0]	TCP_SERVER_MAC_DEFAULT			,	// out	: Default value for the server's MAC address
		input	wire	[31:0]	TCP_SERVER_ADDR_IN				,	// in	: Client mode, Server IP address[31:0]
		output	wire	[31:0]	TCP_SERVER_ADDR_DEFAULT			,	// out	: Default value for the server's IP address[31:0]
		input	wire	[15:0]	TCP_SERVER_PORT_IN				,	// in	: Client mode, Server wating port#[15:0]
		output	wire	[15:0]	TCP_SERVER_PORT_DEFAULT			,	// out	: Default value for the server port #[15:0]
		//		==== User I/F ====
		output	wire			SiTCP_RESET_OUT					,	// out	: System reset for user's module
		//			--- RBCP ---
		output	wire			RBCP_ACT						,	// out	: Indicates that bus access is active.
		output	wire	[31:0]	RBCP_ADDR						,	// out	: Address[31:0]
		output	wire			RBCP_WE							,	// out	: Write enable
		output	wire	[ 7:0]	RBCP_WD							,	// out	: Data[7:0]
		output	wire			RBCP_RE							,	// out	: Read enable
		input	wire			RBCP_ACK						,	// in	: Access acknowledge
		input	wire	[ 7:0]	RBCP_RD							,	// in	: Read data[7:0]
		//			--- TCP ---
		input	wire			USER_SESSION_OPEN_REQ			,	// in	: Request for opening the new session
		output	wire			USER_SESSION_ESTABLISHED		,	// out	: Establish of a session 
		output	wire			USER_SESSION_CLOSE_REQ			,	// out	: Request for closing session.
		input	wire			USER_SESSION_CLOSE_ACK			,	// in	: Acknowledge for USER_SESSION_CLOSE_REQ.
		input	wire	[63:0]	USER_TX_D						,	// in	: Write data
		input	wire	[ 3:0]	USER_TX_B						,	// in	: Byte length of USER_TX_DATA (Set to 0 if not written)
		output	wire			USER_TX_AFULL					,	// out	: Request to stop TX
		input	wire	[15:0]	USER_RX_SIZE					,	// in	: Receive buffer size(byte) caution:Set a value of 4000 or more and (memory size-16) or less
		output	wire			USER_RX_CLR_ENB					,	// out	: Receive buffer Clear Enable
		input	wire			USER_RX_CLR_REQ					,	// in	: Receive buffer Clear Request
		input	wire	[15:0]	USER_RX_RADR					,	// in	: Receive buffer read address in bytes (unused upper bits are set to 0)
		output	wire	[15:0]	USER_RX_WADR					,	// out	: Receive buffer write address in bytes (lower 3 bits are not connected to memory)
		output	wire	[ 7:0]	USER_RX_WENB					,	// out	: Receive buffer byte write enable (big endian)
		output	wire	[63:0]	USER_RX_WDAT						// out	: Receive buffer write data (big endian)
	);
//------------------------------------------------------------------------------
endmodule
