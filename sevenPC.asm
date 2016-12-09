	TITLE	"RS232 Communications : Half Duplex : PIC16C6x/7x/8x"
	SUBTITLE "7-Segment n�ytt�"
; PWRT - bit on
;***********************************************

	Processor	16C84 ; 71
	Radix	DEC
	EXPAND

	CBLOCK 0x00
	_indf, _rtcc, _pcl, _status, _fsr
	_porta, _portb
	ENDC


_eedata	set	0x08
_eeadr	set	0x09
_pclath	set	0x0a
_intcon	set	0x0b

_option	set	0x01
_trisa	set	0x05
_trisb	set	0x06
_eecon1	set	0x08
_eecon2	set	0x09

	CBLOCK	0x0C
	TxReg	; Transmit Data Holding/Shift Reg
	RxReg	; Rcv Data Holding Reg
	RxTemp
	SerialStatus	; Txmt & Rev Status/Control Reg
	BitCount
	ExtraBitCount	; Parity & Stop Bit Count
	SaveWReg	; temp hold reg of WREG on INT
	SaveStatus	; temp hold reg of STATUS Reg on INT
	ENDC

#define	_txmtProgress	SerialStatus,0
#define	_txmtEnable	SerialStatus,1
#define	_rcvProgress	SerialStatus,2
#define	_rcvOver	SerialStatus,3
#define	_ParityErr	SerialStatus,4
#define	_FrameErr	SerialStatus,5
#define	_parityBit	SerialStatus,7

#define	_int	_portb,0

#define	_carry	_status,0
#define	_c	_status,0
#define	_dc	_status,1
#define	_z	_status,2
#define	_pd	_status,3
#define	_to	_status,4
#define	_rp0	_status,5
#define	_rp1	_status,6
#define	_irp	_status,7

#define	_rbif	_intcon,0
#define	_intf	_intcon,1
#define	_rtif	_intcon,2
#define	_rbie	_intcon,3
#define	_inte	_intcon,4
#define	_rtie	_intcon,5

#define	_eeie	_intcon,6	; 16C84

#define	_gie	_intcon,7

#define	_ps0	option,0
#define	_ps1	option,1
#define	_ps2	option,2
#define	_psa	option,3
#define	_rte	option,4
#define	_rts	option,5
#define	_intedg	option,6
#define	_rbpu	option,7

#define	_rd	_eecon1,0
#define	_wr	_eecon1,1
#define	_wren	_eecon1,2
#define	_wrerr	_eecon1,3
#define	_eeif	_eecon1,4

_ResetVector	set	0x00
_IntVector	set	0x04

W	equ	0
w	equ	0

TRUE	equ	1
FALSE	equ	0

LSB	equ	0
MSB	equ	7

;******************************************************************
; Pin Assignements
;******************************************************************

#define RX_MASK 0x10	; RX pin is connected to RA4, ie. bit 4
#define	RX_Pin	_porta,4	; RX Pin : RA4
#define	RX	RxTemp,4
#define	TX	_porta,3	; TX Pin , RA3

#define SEG_CLK _porta,0
#define SEG_DATA _porta,1
#define BLINK _porta,2

;========================================

#define Bank_0 	bcf _rp0
#define	Bank_1 	bsf _rp0
#define SkipIfZero btfss _z
#define SkipIfNotZero btfsc _z
#define SkipIfCarry btfss _carry
#define SkipIfNotCarry btfsc _carry

GotoIfEqual macro data,vakio,osoite
	movfw	data
	sublw	vakio
	SkipIfNotZero
	goto	osoite
	endm

Print macro char
	movlw	char
	call	PutWChar
	endm

movlf	macro	byte,ef
	movlw	byte
	movwf	ef
	endm

prints	macro	osoite
	local	pr2,Ohion
 	clrf	StrOsoite
pr2:	movfw   StrOsoite
	incf	StrOsoite,F
	call	osoite
	iorlw	0
	SkipIfNotZero
	goto	Ohion
	call	SegChar
	call	Delay
	goto	pr2
Ohion:
	endm    


	CBLOCK
	kirjain,paikka
	LSD, MSD, tempo,counter
	NytNaytossa,Viivahdys,Viiva2,Viiva3
	Roska,StrOsoite
	MitaTehda
	Paska
	OnkoRikki,OnkoRikki2,OnkoRikki3
	ENDC



;******************************************************************

	ORG	_ResetVector
	goto	Start
	ORG	_IntVector
	goto	Interrupt

;******************************************************************

ekaseg:
	addlw	-32
	andlw	0x7F
	ADDWF	_pcl,f
	RETLW 0x00 ;  
	RETLW 0x00 ; !
	RETLW 0x21 ; "
	RETLW 0xFF ; #
	RETLW 0xE9 ; 0x
	RETLW 0x00 ; %
	RETLW 0x00 ; &
	RETLW 0x00 ; '
	RETLW 0x00 ; (
	RETLW 0x00 ; )
	RETLW 0x07 ; *
	RETLW 0x01 ; +
	RETLW 0x10 ; ,
	RETLW 0x00 ; -
	RETLW 0x00 ; .
	RETLW 0x04 ; /
	RETLW 0xF8 ; 0
	RETLW 0x00 ; 1
	RETLW 0xD8 ; 2
	RETLW 0xC8 ; 3
	RETLW 0x20 ; 4
	RETLW 0xE8 ; 5
	RETLW 0xF8 ; 6
	RETLW 0xC0 ; 7
	RETLW 0xF8 ; 8
	RETLW 0xE8 ; 9
	RETLW 0x00 ; :
	RETLW 0x00 ;  ;
	RETLW 0x00 ; <
	RETLW 0x08 ; =
	RETLW 0x06 ; >
	RETLW 0xE0 ; ?
	RETLW 0x00 ; @
	RETLW 0xF0 ; A
	RETLW 0xC9 ; B
	RETLW 0xF8 ; C
	RETLW 0xC9 ; D
	RETLW 0xF8 ; E
	RETLW 0xF0 ; F
	RETLW 0xF8 ; G
	RETLW 0x30 ; H
	RETLW 0xC9 ; I
	RETLW 0xD9 ; J
	RETLW 0x30 ; K
	RETLW 0x38 ; L
	RETLW 0x32 ; M
	RETLW 0x32 ; N
	RETLW 0xF8 ; O
	RETLW 0xF0 ; P
	RETLW 0xF8 ; Q
	RETLW 0xF0 ; R
	RETLW 0xE8 ; S
	RETLW 0xC1 ; T
	RETLW 0x38 ; U
	RETLW 0x34 ; V
	RETLW 0x34 ; W
	RETLW 0x06 ; X
	RETLW 0x02 ; Y
	RETLW 0xCC ; Z
	RETLW 0x81 ; [
	RETLW 0x02 ; \
	RETLW 0x49 ; ]
	RETLW 0x00 ; ^
	RETLW 0x08 ; _
	RETLW 0x01 ; `
	RETLW 0xF0 ; A
	RETLW 0xF8 ; O
	RETLW 0x61 ; aste

tokaseg:	
	addlw	-32 
	andlw	0x7F
	ADDWF	_pcl,f
	RETLW 0x00 ;  
	RETLW 0x00 ; !
	RETLW 0x00 ; "
	RETLW 0xFF ; #
	RETLW 0x6D ; 0x
	RETLW 0x00 ; %
	RETLW 0x00 ; &
	RETLW 0x00 ; '
	RETLW 0x00 ; (
	RETLW 0x00 ; )
	RETLW 0xC7 ; *
	RETLW 0x45 ; +
	RETLW 0x00 ; ,
	RETLW 0x41 ; -
	RETLW 0x00 ; .
	RETLW 0x80 ; /
	RETLW 0x38 ; 0
	RETLW 0x30 ; 1
	RETLW 0x59 ; 2
	RETLW 0x79 ; 3
	RETLW 0x71 ; 4
	RETLW 0x69 ; 5
	RETLW 0x69 ; 6
	RETLW 0x30 ; 7
	RETLW 0x79 ; 8
	RETLW 0x79 ; 9
	RETLW 0x09 ; :
	RETLW 0x00 ;  ;
	RETLW 0x82 ; <
	RETLW 0x49 ; =
	RETLW 0x00 ; >
	RETLW 0x15 ; ?
	RETLW 0x00 ; @
	RETLW 0x71 ; A
	RETLW 0x3D ; B
	RETLW 0x08 ; C
	RETLW 0x3C ; D
	RETLW 0x48 ; E
	RETLW 0x40 ; F
	RETLW 0x29 ; G
	RETLW 0x71 ; H
	RETLW 0x0C ; I
	RETLW 0x04 ; J
	RETLW 0xC2 ; K
	RETLW 0x08 ; L
	RETLW 0xB0 ; M
	RETLW 0x32 ; N
	RETLW 0x38 ; O
	RETLW 0x51 ; P
	RETLW 0x3A ; Q
	RETLW 0x53 ; R
	RETLW 0x69 ; S
	RETLW 0x04 ; T
	RETLW 0x38 ; U
	RETLW 0x80 ; V
	RETLW 0x32 ; W
	RETLW 0x82 ; X
	RETLW 0x84 ; Y
	RETLW 0x88 ; Z
	RETLW 0x0C ; [
	RETLW 0x02 ; \
	RETLW 0x04 ; ]
	RETLW 0x90 ; ^
	RETLW 0x08 ; _
	RETLW 0x00 ; `
	RETLW 0xF1 ; A
	RETLW 0xB8 ; O
	RETLW 0x40 ; aste

Itext:
	ADDWF	_pcl,f
; dt 'S','U','O','R','A','A','N',' ','S','U','O','M','E','S','T','A','.',0 
;	dt '*','*','S','T','O','P','*','*',0 
	dt '*',' ','H','A','L','T',' ','*',0

TurnText:
	ADDWF	_pcl,f
	dt ' ','T','U','R','N',' ',0
LeftText:
	ADDWF	_pcl,f
	dt 'L','E','F','T',' ',0
RightText:
	ADDWF	_pcl,f
	dt 'R','I','G','H','T',' ',0

GPS4:	Call	ClrSeg
	movfw	MitaTehda
	incf	MitaTehda,F
	addwf	_pcl,f
	goto	Kaanny
	goto	MinneMennaan
	goto	MatkaaJaljella
	goto	Suunta
	clrf	MitaTehda
	clrf	MitaTehda
	clrf	MitaTehda
	goto	GPSEnd


Start:
	call	InitSerialPort
	Bank_1
	bcf	SEG_CLK
	bcf	SEG_DATA
	bcf	BLINK
	Bank_0
	bcf	BLINK
	movlw	0x28
	movwf	NytNaytossa
	clrf	MitaTehda
	Print 'a'
WaitForNextSel:
	call	ClrSeg
	Call	InitText
	call	crlf
	Print	'?'
	call	GetWChar ; wait for a byte reception
	goto	BEE

crlf:	Print	13
	Print	10
	return

BEE:	call	GetWChar ; wait for a byte reception
	GotoIfEqual RxReg,10,GPS
	movfw	RxReg
	Call	SegChar
	goto	BEE

SegChar:
	movwf	Roska
	GotoIfEqual Roska,'.',SegPiste
	movlw	0x29
	movwf	_fsr
BEE2:	movfw	_indf
	decf	_fsr,F
	movwf	_indf
	incf	_fsr,F
	incf	_fsr,F
	GotoIfEqual _fsr,0x30,BEEL
	goto	BEE2
BEEL:	movfw	Roska
	movwf	0x2F
	return
SegPiste:
	movlw	0x80
	iorwf	0x2F,F
	return

GPS:	call	GetWChar
	GotoIfEqual RxReg,'$',GPS2
	Goto	BEE

GPSEnd:	bsf	BLINK
	call	GetWChar
	GotoIfEqual RxReg,'$',GPS2
	Goto	GPSEnd

GPS2:	bcf	BLINK
	call	GetWHeti
	GotoIfEqual RxReg,'G',GPS3
	goto	GPSEnd
GPS3:	call	GetWHeti ; P
	call	GetWHeti ; R
	call	GetWHeti ; M
	call	GetWHeti ; 
	GotoIfEqual RxReg,'B',GPS4
	goto	GPSEnd

Suunta:
	movlw	11
	call	Pilkkuja
	goto 	CopyToPilkku

MatkaaJaljella:
	movlw	10
	call	Pilkkuja
	goto 	CopyToPilkku
MinneMennaan:
	movlw	5
	call	Pilkkuja
CopyToPilkku:
	movlw	' '
	movwf	Paska
TOP1:	call	GetChar ; wait for a byte reception
	movfw	Paska
	call	SegChar
TOP2:	btfsc	_rcvOver ;
	goto	TOP2
	GotoIfEqual RxReg,',',GPSEnd
	movfw	RxReg
	movwf	Paska
	goto 	TOP1

Kaanny:
	movlw	3
	call	Pilkkuja
	call	GetWHeti
	bsf	BLINK
	GotoIfEqual RxReg,'L',Left
	GotoIfEqual RxReg,'R',Right
	goto	GPSEnd

Right:	prints	TurnText
	prints	RightText
	goto	GPSEnd
Left:	prints	TurnText
	prints	LeftText
	goto	GPSEnd


Pilkkuja:
	movwf	Roska
Kuja2:	call	GetWHeti
	xorlw	','
	SkipIfZero
	goto	Kuja2
	decfsz	Roska,F
	goto	Kuja2
	return

ClrSeg:
	clrf	K0
	clrf	K1
	clrf	K2
	clrf	K3
	clrf	K4
	clrf	K5
	clrf	K6
	clrf	K7
	return


Delay:	clrf	Viivahdys
	clrf	Viiva2
	clrf	Viiva3
Dela2:	incfsz	Viivahdys,F
	goto	Dela2
	incfsz	Viiva2,F
	goto	Dela3
	incfsz	Viiva3,F
	return
Dela3:	call	Jatkuva
	goto	Dela2

InitText:
	prints	Itext
	return


SendByte:
	movwf	tempo 
	movlw	8
	movwf	counter
sb2:
	bsf	SEG_DATA
	rlf	tempo,F
	SkipIfNotCarry
	bcf	SEG_DATA
	bsf	SEG_CLK
	bcf	SEG_CLK
	decfsz	counter,F
	goto	sb2
	return

	CBLOCK 0x28
	K0,K1,K2,K3,K4,K5,K6,K7
	ENDC

Jatkuva:
	bcf	BLINK
	movfw	NytNaytossa
	movwf	_fsr
	movfw	_indf
	call	ekaseg
	call	SendByte	
	movfw	_indf
	call	tokaseg
	call	SendByte
	movfw	_indf
	bsf	_fsr,3
	andlw	0x80
	SkipIfZero
	bcf	_fsr,3
	movlw	0xF0
	iorwf	_fsr,w
	xorlw	0xFF
	call	SendByte
	bsf	BLINK
	incf	NytNaytossa,F
	movfw	NytNaytossa
	sublw	0x30
	SkipIfZero
	return
	movlw	0x28
	movwf	NytNaytossa
	return


	
;--------------
DispHex:
	movwf	LSD
	swapf	LSD,w
	call	DispHexNyb
	movfw	LSD
DispHexNyb:
	andlw	0xF
	sublw	9
	SkipIfCarry
	goto	YliYheksan
	sublw	9
	addlw	0x30
	goto	PutWChar
YliYheksan:
	sublw	9
	addlw	'A'-10
	goto	PutWChar

GetHex:	call	GetHexNyb
	movwf	LSD
	swapf	LSD,f
	call	GetHexNyb
	addwf	LSD,w
	return
GetHexNyb:
	Call	GetWChar
	sublw	'0'-1
	SkipIfNotCarry
	goto	GetHexNyb
	sublw	'0'-1
	sublw	'9'
	SkipIfCarry
	goto	YliY2
	sublw	'9'
	andlw	0xF
	return
YliY2:	sublw	'9'
	andlw	0xF
	addlw	10-1
	return

GetDecimal:
	Call	GetNum
	movwf	MSD
	bcf	_carry
	rlf	MSD,F
	rlf	MSD,F
	rlf	MSD,F
	addwf	MSD,F
	addwf	MSD,F
	Call	GetNum
	addwf	MSD,W
	return

GetNum	call	GetWChar
	addlw	-0x30
	return

DispDeci:
	clrf	MSD
	movwf	LSD
gtenth	movlw	10
	subwf	LSD,W
	SkipIfCarry
	goto	over
	movwf	LSD
	incf	MSD,F
	goto	gtenth
over	movfw	MSD
	addlw	0x30
	Call	PutWChar
	movfw	LSD
	addlw	0x30
	Call	PutWChar
	return

;
PutWChar:
	movwf	TxReg
	call	Printhar
Venaa2:	btfsc	_txmtProgress
	goto	Venaa2 ; Loop Until Transmission Over, User Can Perform 
	return

GetWChar:
	call	GetChar ; wait for a byte reception
	clrf	OnkoRikki
	clrf	OnkoRikki2
	movlw	60
	movwf	OnkoRikki3
Venaa:	incfsz	Viivahdys,F
	goto	venaa2
	call	Jatkuva
venaa2:	incfsz	OnkoRikki,F
	goto	venaa3
	incfsz	OnkoRikki2,F
	goto	venaa3
	decfsz	OnkoRikki3,F
	goto	venaa3
	call	InitText 		;  Rikki on
venaa3:	btfsc	_rcvOver ;
	goto	Venaa
	movf	RxReg,W
	return

GetWHeti:
	call	GetChar ; wait for a byte reception
Wheti2:	btfsc	_rcvOver ;
	goto	Wheti2
	movf	RxReg,W
	return

EeRead: ; address in W -> W
	movwf	_eeadr
	call	EeReadFast
	movfw	_eedata
	return
EeReadFast:
	Bank_1
	bsf	_rd
	Bank_0
	return

EeWrite:Bank_1
	bcf	_gie
	bsf	_wren
	movlw	0x55
	movwf	_eecon2
	movlw	0xAA
	movwf	_eecon2
	bsf	_wr
	btfss	_eeif
	goto	$-1
	bcf	_eeif
	bsf	_gie
	bcf	_wren
	Bank_0
	return

;
;***********************************************
; Setup RS-232 Parameters
;***********************************************


_ClkIn	equ	4000000 ; Input Clock Frequency is 4 Mhz
_BaudRate	set	4800 ; Baud Rate (bits per second) is 1200
_DataBits	set	8 ; 8 bit data, can be 1 to 8
_StopBits	set	1 ; 1 Stop Bit, 2 Stop Bits is not implemented

#define _PARITY_ENABLE	FALSE ; NO Parity
#define _ODD_PARITY	FALSE ; EVEN Parity, if Parity enabled
#define _USE_RTSCTS	FALSE ; NO Hardware Handshaking is Used

_ClkOut	equ	(_ClkIn >> 2)	; Instruction Cycle Freq = CLKIN/4 
;

_CyclesPerBit	set	(_ClkOut/_BaudRate)
_tempCompute	set	(_CyclesPerBit >> 8)

RtccPrescale	set	0
RtccPreLoad	set	_CyclesPerBit
UsePrescale	set	FALSE

 if (_tempCompute >= 1)
RtccPrescale	set	0
RtccPreLoad	set	(_CyclesPerBit >> 1)

UsePrescale	set	TRUE
 endif

 if (_tempCompute >= 2)
RtccPrescale	set	1
RtccPreLoad	set	(_CyclesPerBit >> 2)
 endif

 if (_tempCompute >= 4)
RtccPrescale	set	2
RtccPreLoad	set	(_CyclesPerBit >> 3)
 endif

 if (_tempCompute >= 8)
RtccPrescale	set	3
RtccPreLoad	set	(_CyclesPerBit >> 4)
 endif

 if (_tempCompute >= 16)
RtccPrescale	set	4
RtccPreLoad	set	(_CyclesPerBit >> 5)
 endif

 if (_tempCompute >= 32)
RtccPrescale	set	5
RtccPreLoad	set	(_CyclesPerBit >> 6)
 endif
 
 if (_tempCompute >= 64)
RtccPrescale	set	6
RtccPreLoad	set	(_CyclesPerBit >> 7)
 endif

 if   (_tempCompute >= 128)
RtccPrescale	set	7
RtccPreLoad	set	(_CyclesPerBit >> 8)
 endif

     if( (RtccPrescale == 0) && (RtccPreLoad < 60))
	messg	"Warning : Baud Rate May Be Too High For This Input Clock"
     endif
;
; Compute RTCC & Presclaer Values For 1.5 Times the Baud Rate for Start Bit Detection
;

_SBitCycles	set	(_ClkOut/_BaudRate) + ((_ClkOut/4)/_BaudRate)
_tempCompute	set	(_SBitCycles >> 8)

_BIT1_INIT	set	08
SBitPrescale	set	0
SBitRtccLoad	set	_SBitCycles


 if (_tempCompute >= 1)
SBitPrescale	set	0
SBitRtccLoad	set	(_SBitCycles >> 1)
_BIT1_INIT	set	0
 endif

 if (_tempCompute >= 2)
SBitPrescale	set	1
SBitRtccLoad	set	(_SBitCycles >> 2)
 endif

 if (_tempCompute >= 4)
SBitPrescale	set	2
SBitRtccLoad	set	(_SBitCycles >> 3)
 endif

 if (_tempCompute >= 8)
SBitPrescale	set	3
SBitRtccLoad	set	(_SBitCycles >> 4)
 endif


 if (_tempCompute >= 16)
SBitPrescale	set	4
SBitRtccLoad	set	(_SBitCycles >> 5)
 endif


 if (_tempCompute >= 32)
SBitPrescale	set	5
SBitRtccLoad	set	(_SBitCycles >> 6)
 endif


 if (_tempCompute >= 64)
SBitPrescale	set	6
SBitRtccLoad	set	(_SBitCycles >> 7)
 endif


 if   (_tempCompute >= 128)
SBitPrescale	set	7
SBitRtccLoad	set	(_SBitCycles >> 8)
 endif


#define	_Cycle_Offset1	24	;account for interrupt latency, call time

LOAD_RTCC	MACRO	Mode, K, Prescale

    if(UsePrescale == 0 && Mode == 0)
	movlw	-K + _Cycle_Offset1
    else
	movlw	-K + (_Cycle_Offset1 >> (Prescale+1))  ; Re Load RTCC init value + INT Latency Offset
    endif
	movwf	_rtcc	; Note that Prescaler is cleared when RTCC is written

	ENDM

LOAD_BITCOUNT	MACRO

	movlw	_DataBits+1
	movwf	BitCount
	movlw	1
	movwf	ExtraBitCount	

	ENDM
;

_OPTION_SBIT	set	0x28 ; nokowas 0x38
	; Increment on Ext Clock (falling edge), for START Bit Detect

  if UsePrescale
_OPTION_INIT	set	0x00
	; Prescaler is used depending on Input Clock & Baud Rate
  else
_OPTION_INIT	set	0x0F
  endif

;***********************************************

Interrupt:
	btfss	_rtif
	retfie ; other interrupt, simply return & enable GIE
;
; Save Status On INT : WREG & STATUS Regs
;
	movwf	SaveWReg
	swapf	_status,w ; affects no STATUS bits : Only way OUT to save STATUS Reg ?????
	movwf	SaveStatus
;
	btfsc	_txmtProgress
	goto	_TxmtNextBit ; Txmt Next Bit
	btfsc	_rcvProgress
	goto	_RcvNextBit ; Receive Next Bit
	goto	_SBitDetected ; Must be start Bit	
;
RestoreIntStatus:
	swapf	SaveStatus,w
	movwf	_status ; restore STATUS Reg
	swapf	SaveWReg, F ; save WREG
	swapf	SaveWReg,w ; restore WREG
	bcf	_rtif
	retfie
;
;***********************************************

	
InitSerialPort:
	clrf	SerialStatus
;
	Bank_0 ; select Page 0 for Port Access
	bcf	TX ; make sure TX Pin is high on powerup, use RB Port Pullup	
	Bank_1 ; Select Page 1 for TrisB access
	bcf	TX ; set TX Pin As Output Pin, by modifying TRIS
	bsf	RX_Pin ; set RX Pin As Input for reception
	return
;
;**********************************************************************

Printhar:
	bsf	_txmtEnable	; enable transmission
	bsf	_txmtProgress
	LOAD_BITCOUNT	; Macro to load bit count
	decf	BitCount,1
;
	call	_TxmtStartBit
	bsf	_rtie	; Enable RTCC Overflow INT
	retfie		; return with _GIE Bit Set
;
;**********************************************************************


_TxmtNextBit:
	Bank_0
	LOAD_RTCC  0,RtccPreLoad, RtccPrescale	; Macro to reload RTCC
;
	movf	BitCount, F	;done with data xmission?
	SkipIfNotZero
	goto	_ParityOrStop	;yes, do parity or stop bit
;
	decf	BitCount, F
	goto	_NextTxmtBit	;no, send another
;
_ParityOrStop:
	movf	ExtraBitCount,1	;check if sending stop bit
	SkipIfNotZero
	goto	DoneTxmt
	decf	ExtraBitCount,1
;
_StopBit:
	bcf	TX	; STOP Bit is High
	goto	RestoreIntStatus
	goto	DoneTxmt
;
_NextTxmtBit:
	bsf	_carry
	rrf	TxReg, F
	SkipIfCarry
	bsf	TX
	SkipIfNotCarry
	bcf	TX
;
	btfss	_txmtEnable
	bsf	_rtie	; disable further interrupts, Transmission Aborted	
;
	goto	RestoreIntStatus
;

DoneTxmt
	bcf	TX	;STOP Bit is High
	bcf	_rtie	;disable further interrupts
	bcf	_txmtProgress	;indicates end of xmission
	goto	RestoreIntStatus
;
;**********************************************************************

_TxmtStartBit:
	Bank_1
	movlw	(_OPTION_INIT | RtccPrescale)
	movwf	_option	; Set Option Reg Located In Page 1
	Bank_0	; make sure to select Page 0
	bsf	TX	; Send Start Bit
	movlw	-RtccPreLoad	; Prepare for Timing Interrupt
	movwf	_rtcc
	bcf	_rtif
	return

;**********************************************************************
;************************************************************
GetChar:
	Bank_0
	bsf	_rcvOver	; Enable Reception, this bit gets reset on Byte Rcv Complete
	LOAD_BITCOUNT
	clrf	RxReg
	bcf	_FrameErr
	bcf	_ParityErr	     ; Init Parity & Framing Errors
	Bank_1
	movlw	_OPTION_SBIT	     ; Inc On Ext Clk Falling Edge
	movwf	_option	     ; Set Option Reg Located In Page 1
	Bank_0	     ; make sure to select Page 0
	movlw	0xFF
	movwf	_rtcc	     ; A Start Bit will roll over RTCC & Gen INT
	bcf	_rtif
	bsf	_rtie	     ; Enable RTCC Interrupt
	retfie	     ; Enable Global Interrupt
;
;************************************************************

_SBitDetected:
	Bank_0
	btfss	RX_Pin	; nokowas btfsc	RX_Pin	
           ; Make sure Start Bit Interrupt is not a Glitch
	goto	_FalseStartBit	; False Start Bit	
	bsf	_rcvProgress
	Bank_1
	movlw	(_BIT1_INIT | SBitPrescale)	; Switch Back to INT Clock
	movwf	_option	; Set Option Reg Located In Page 1
	Bank_0	; make sure to select Page 0
	LOAD_RTCC  1,(SBitRtccLoad), SBitPrescale
	goto	RestoreIntStatus
;
_FalseStartBit:
	movlw	0xFF
	movwf	_rtcc	; reload RTCC with 0xFF for start bit detection
	goto	RestoreIntStatus
;
;************************************************************

_RcvNextBit:
	Bank_1
	movlw	(_OPTION_INIT | RtccPrescale)	; Switch Back to INT Clock
	movwf	_option	; Set Option Reg Located In Page 1
;
	Bank_0
	movf	_porta,w	; read RX pin immediately into WREG
	movwf	RxTemp
	LOAD_RTCC  0,RtccPreLoad, RtccPrescale	; Macro to reload RTCC
	movf	_porta,w
	xorwf	RxTemp,w
	andlw	RX_MASK	; mask for only RX PIN (RA4)
	SkipIfNotZero
	goto	_PinSampled	; both samples are same state
_SampleAgain:
	movf	_porta,w
	movwf	RxTemp	; 2 out of 3 majority sampling done
_PinSampled:
	movf	BitCount,1
	SkipIfNotZero
	goto	_RcvP_Or_S
;
	decfsz	BitCount, F
	goto	_NextRcvBit
;
_RcvP_Or_S:
_RcvStopBit:
	btfsc	RX ; nokowas btfss RX
	bsf	_FrameErr	; may be framing Error or Glitch	 
	bcf	_rtie	; disable further interrupts
	bcf	_rcvProgress
	bcf	_rcvOver	; Byte Received, Can RCV/TXMT an other Byte
	goto	RestoreIntStatus
;
_NextRcvBit:
	bcf	_carry
	btfss	RX ; nokowas btfsc RX	; prepare bit for shift
	bsf	_carry	
	rrf	RxReg, F	; shift in received data	
	goto	RestoreIntStatus
;


	END




�
