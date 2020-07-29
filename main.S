#include <avr/io.h>
#include "enc28j60_asm.h"

;This code receives data (audio) from an I2S-MEMS-microphone and transmits it over LAN
;using an ENC28J60. For details see README.
;
;(c) 2020 by kitten_nb_five
;
;licence: AGPL v3 or later
;
;THIS CODE IS PROVIDED WITHOUT ANY WARRANTY! 


;DO NOT CHANGE!
#define SIZE_TX 252
#define WRITE_REG (1<<6)

;registers
ws_00=3
ws_ff=4

data1=5
data2=6
data3=7

temp=16
bytecnt=17
flag_enc_do_send=18
flag_enc_transfer_ongoing=19

func0_ret=23
func1=24
func2=25

;26-31 reserved

;X pointer to buffer for RX I2S

;Z pointer to buffer for TX ENC


.text
.global main

.macro cs_low
	cbi _SFR_IO_ADDR(PORTB), 2
.endm

.macro cs_high
	sbi _SFR_IO_ADDR(PORTB), 2
.endm

.macro load_send_ENC
	ld func0_ret, Z+
	sts SPDR, func0_ret
1:	
	lds temp, SPSR
	sbrs temp, SPIF
	rjmp 1b
.endm

.macro m_write_ctrl_reg
	cs_low
	sts SPDR, func0_ret
1:	
	lds temp, SPSR
	sbrs temp, SPIF
	rjmp 1b
	sts SPDR, func1
1:
	lds temp, SPSR
	sbrs temp, SPIF
	rjmp 1b
	cs_high
.endm


main:
	rcall init_hw
	
	rcall enc_init
	
	rcall enc_write_header
	
	;RX I2S
	ldi XL, lo8(buf0)
	ldi XH, hi8(buf0)
	
	;TX ENC
	ldi ZL, lo8(buf1)
	ldi ZH, hi8(buf1)

	clr flag_enc_do_send
	clr flag_enc_transfer_ongoing
	
mainloop:	
	;4x WS=1

	ldi bytecnt, 4

wordsel_ff_loop:

	sts UDR0, ws_ff
	
	tst flag_enc_transfer_ongoing
	breq ff_no_send
	
	load_send_ENC
	load_send_ENC
	
	cpi ZL, 252
	brne ff_cont
	clr ZL
	cs_high
	;trigger send	
	ldi func0_ret, (1<<7)|ECON1
	ldi func1, (1<<TXRTS)
	m_write_ctrl_reg
	
	clr flag_enc_transfer_ongoing
	
ff_no_send:

ff_cont:
	
1:
	lds temp, UCSR0A
	andi temp, (1<<UDRE0)
	breq 1b
	
	lds temp, UDR0
	
	dec bytecnt
	brne wordsel_ff_loop

	;4x WS=0 + sample
	
	sts UDR0, ws_00
	
	cpi XL, 252-3
	brne wait1
	ldi flag_enc_do_send, 1
	
wait1:
	lds temp, UCSR0A
	andi temp, (1<<UDRE0)
	breq wait1
	
	lds temp, UDR0 ;dummy read - important, do not remove!

	sts UDR0, ws_00
	
	tst flag_enc_do_send
	breq wait2

	ldi func0_ret, WRITE_REG|EWRPTL
	ldi func1, lo8(2000+15)
	m_write_ctrl_reg
	
wait2:
	lds temp, UCSR0A
	andi temp, (1<<UDRE0)
	breq wait2	
	lds data1, UDR0
	
	sts UDR0, ws_00
	
	tst flag_enc_do_send
	breq wait3
	
	ldi func0_ret, WRITE_REG|EWRPTH
	ldi func1, hi8(2000+15)
	m_write_ctrl_reg
	
wait3:
	lds temp, UCSR0A
	andi temp, (1<<UDRE0)
	breq wait3
	lds data2, UDR0

	sts UDR0, ws_00
	
	tst flag_enc_do_send
	breq wait4
	
	cs_low
	ldi func0_ret, (1<<6)|(1<<5)|0b11010 ;memory write
	rcall spi_read_write
	
wait4:
	lds temp, UCSR0A
	andi temp, (1<<UDRE0)
	breq wait4
	lds data3, UDR0
	
	;I2S-data is delayed by one clock-cycle (2MHz Masterclock)
	;so we need a shift here
	lsl data3
	rol data2
	rol data1
	
	st X+, data1
	st X+, data2
	st X+, data3

	tst flag_enc_do_send
	breq no_switch
	;switch buffers
	clr XL
	ldi temp,1
	eor r27, temp
	eor r31, temp
	ldi flag_enc_transfer_ongoing, 1
	clr flag_enc_do_send
	
	
no_switch:

	rjmp mainloop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_hw:
	;USART as SPI 2MHz
	ldi temp, 0
	sts UBRR0H, temp
	sts UBRR0L, temp
	ldi temp, (1<<PD4)
	out _SFR_IO_ADDR(DDRD), temp
	ldi temp, (1<<UMSEL01)|(1<<UMSEL00)
	sts UCSR0C, temp
	ldi temp, (1<<RXEN0)|(1<<TXEN0)
	sts UCSR0B, temp
	ldi temp, 0
	sts UBRR0H, temp
	ldi temp, 4
	sts UBRR0L, temp
	
	
	;SPI for ENC28J60 10MHz - min 8MHz due to silicon bug!
	ldi temp, (1<<PB2)|(1<<PB3)|(1<<PB5)
	out _SFR_IO_ADDR(DDRB), temp
	ldi temp, (1<<SPE)|(1<<MSTR)
	sts SPCR, temp
	ldi temp, (1<<SPI2X)
	sts SPSR, temp

	
	clr ws_00
	ser temp
	mov ws_ff, temp
	
	ret

;func0_ret contains value to be written, returns received value
spi_read_write:
	push temp
	sts SPDR, func0_ret
1:	
	lds temp, SPSR
	sbrs temp, SPIF
	rjmp 1b
	lds func0_ret, SPDR
	pop temp
	ret

;func0_ret contains addr, returns received val
read_ctrl_reg:
	cs_low
	rcall spi_read_write
	ldi func0_ret, 0
	rcall spi_read_write
	cs_high
	ret

;func0_ret contains addr, func1 contains val, returns nothing
write_ctrl_reg:
	cs_low
	rcall spi_read_write
	mov func0_ret, func1
	rcall spi_read_write
	cs_high
	ret

;func0_ret contains addr, func1 contains mask, returns nothing
set_bits_in_register:
	cs_low
	ori func0_ret, (1<<7)
	rcall spi_read_write
	mov func0_ret, func1
	rcall spi_read_write
	cs_high
	ret

;func0_ret contains bank, returns nothing
switch_bank:
	push temp
	mov temp, func0_ret ; save bank
	ldi func0_ret, 0x1f
	rcall read_ctrl_reg
	andi func0_ret, ~((1<<1)|(1<<0))
	or func0_ret, temp
	mov func1, func0_ret
	ldi func0_ret, WRITE_REG|0x1f
	rcall write_ctrl_reg
	pop temp
	ret

;func0_ret contains addr, func1 contains val_high, func2 contains val_low, returns nothing
write_phy_reg:
	push func1
	
	mov func1, func0_ret ; register
	ldi func0_ret, WRITE_REG|MIREGADR
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|MIWRL
	mov func1, func2
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|MIWRH
	pop func1
	rcall write_ctrl_reg
	
	;11us @20MHz == 220 ticks
	ldi temp, 74 ;1
1:
	dec temp ;1
	brne 1b ;2

1:
	ldi func0_ret, MISTAT
	cs_low
	rcall spi_read_write
	ldi func0_ret, 0
	rcall spi_read_write ;dummy read for MI-registers!
	ldi func0_ret, 0
	rcall spi_read_write
	cs_high
	sbrc func0_ret, BUSY
	rjmp 1b
	ret
	
;no args, returns nothing
enc_init:
	;bank 0
	ldi func0_ret, 0
	rcall switch_bank
	
	ldi func0_ret, WRITE_REG|ERXSTL
	ldi func1, 0
	rcall write_ctrl_reg
	ldi func0_ret, WRITE_REG|ERXSTH
	ldi func1, 0
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|ERXNDL
	ldi func1, lo8(1600)
	rcall write_ctrl_reg
	ldi func0_ret, WRITE_REG|ERXNDH
	ldi func1, hi8(1600)
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|ERXWRPTL
	ldi func1, 0
	rcall write_ctrl_reg
	ldi func0_ret, WRITE_REG|ERXWRPTH
	ldi func1, 0
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|ETXSTL
	ldi func1, lo8(2000)
	rcall write_ctrl_reg
	ldi func0_ret, WRITE_REG|ETXSTH
	ldi func1, hi8(2000)
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|ETXNDL
	ldi func1, lo8(2000+15+SIZE_TX-1)
	rcall write_ctrl_reg
	ldi func0_ret, WRITE_REG|ETXNDH
	ldi func1, hi8(2000+15+SIZE_TX-1)
	rcall write_ctrl_reg
	
	;bank 2
	ldi func0_ret, 2
	rcall switch_bank
	
	ldi func0_ret, WRITE_REG|MACON1
	ldi func1, (1<<RXPAUS)|(1<<MARXEN)
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|MACON3
	ldi func1, (1<<PADCFG0)|(1<<TXCRCEN)
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|MACON4
	ldi func1, (1<<DEFER)
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|MABBIPG
	ldi func1, 0x12
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|MAIPGL
	ldi func1, 0x12
	rcall write_ctrl_reg
	ldi func0_ret, WRITE_REG|MAIPGH
	ldi func1, 0x0C
	rcall write_ctrl_reg
	
	;bank 3
	ldi func0_ret, 3
	rcall switch_bank
	
	ldi func0_ret, WRITE_REG|ECOCON
	ldi func1, 0
	rcall write_ctrl_reg
	
	;back to 0
	ldi func0_ret, 0
	rcall switch_bank
	
	;phy
	ldi func0_ret, PHCON2
	ldi func1, lo8((1<<HDLDIS))
	ldi func2, hi8((1<<HDLDIS))
	rcall write_phy_reg
	
	ldi func0_ret, PHCON1
	ldi func1, 0
	ldi func2, 0
	rcall write_phy_reg
	
	ret

;no args, returns nothing
enc_write_header:
	ldi func0_ret, WRITE_REG|EWRPTL
	ldi func1, lo8(2000)
	rcall write_ctrl_reg
	
	ldi func0_ret, WRITE_REG|EWRPTH
	ldi func1, hi8(2000)
	rcall write_ctrl_reg
	
	cs_low
	ldi func0_ret, (1<<6)|(1<<5)|0b11010 ;memory write
	rcall spi_read_write
	
	;PACKET CONTROL BYTE
	ldi func0_ret, 0
	rcall spi_read_write
	
	;MAC TO = 6*0xff
	ldi temp, 6
1:
	ldi func0_ret, 0xff
	rcall spi_read_write
	dec temp
	brne 1b

	;MAC FROM = 6*0x00
	ldi temp, 6
1:
	ldi func0_ret, 0x00
	rcall spi_read_write
	dec temp
	brne 1b
	
	;size/ethertype = 0x0000
	ldi func0_ret, 0x00
	rcall spi_read_write
	ldi func0_ret, 0x00
	rcall spi_read_write
	cs_high
	
	ret


.data

;as adds 0x100 offset to avoid GPR and stuff
;DO NOT CHANGE!

.org 0x100
buf0:
	.zero 256

.org 0x200
buf1:
	.zero 256
