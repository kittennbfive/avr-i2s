/*
register-/bit-definitions for ENC28J60

(c) 2020 by kitten_nb_five

AGPL v3 or later

THIS CODE IS PROVIDED WITHOUT ANY WARRANTY!
*/

#ifndef __ENC28J60_H__
#define __ENC28J60_H__

//bank 0
#define ERDPTL 0x00
#define ERDPTH 0x01
#define EWRPTL 0x02
#define EWRPTH 0x03
#define ETXSTL 0x04
#define ETXSTH 0x05
#define ETXNDL 0x06
#define ETXNDH 0x07
#define ERXSTL 0x08
#define ERXSTH 0x09
#define ERXNDL 0x0A
#define ERXNDH 0x0B
#define ERXRDPTL 0x0C
#define ERXRDPTH 0x0D
#define ERXWRPTL 0x0E
#define ERXWRPTH 0x0F
#define EDMASTL 0x10
#define EDMASTH 0x11
#define EDMANDL 0x12
#define EDMANDH 0x13
#define EDMADSTL 0x14
#define EDMADSTH 0x15
#define EDMACSL 0x16
#define EDMACSH 0x17

//bank 1
#define EHT0 0x00
#define EHT1 0x01
#define EHT2 0x02
#define EHT3 0x03
#define EHT4 0x04
#define EHT5 0x05
#define EHT6 0x06
#define EHT7 0x07
#define EPMM0 0x08
#define EPMM1 0x09
#define EPMM2 0x0A
#define EPMM3 0x0B
#define EPMM4 0x0C
#define EPMM5 0x0D
#define EPMM6 0x0E
#define EPMM7 0x0F
#define EPMCSL 0x10
#define EPMCSH 0x11
#define EPMOL 0x14
#define EPMOH 0x15
#define ERXFCON 0x18
#define EPKTCNT 0x19

//bank 2
#define MACON1 0x00
#define MACON3 0x02
#define MACON4 0x03
#define MABBIPG 0x04
#define MAIPGL 0x06
#define MAIPGH 0x07
#define MACLCON1 0x08
#define MACLCON2 0x09
#define MAMXFLL 0x0A
#define MAMXFLH 0x0B
#define MICMD 0x12
#define MIREGADR 0x14
#define MIWRL 0x16
#define MIWRH 0x17
#define MIRDL 0x18
#define MIRDH 0x19

//bank 3
#define MAADR5 0x00
#define MAADR6 0x01
#define MAADR3 0x02
#define MAADR4 0x03
#define MAADR1 0x04
#define MAADR2 0x05
#define EBSTSD 0x06
#define EBSTCON 0x07
#define EBSTCSL 0x08
#define EBSTCSH 0x09
#define MISTAT 0x0A
#define EREVID 0x12
#define ECOCON 0x15
#define EFLOCON 0x17
#define EPAUSL 0x18
#define EPAUSH 0x19

//every bank
#define EIE 0x1B
#define EIR 0x1C
#define ESTAT 0x1D
#define ECON2 0x1E
#define ECON1 0x1F


//ESTAT
#define INT 7
#define BUFER 6
#define LATECOL 4
#define RXBUSY 2
#define TXABRT 1
#define CLKRDY 0

//ECON2
#define AUTOINC 7
#define PKTDEC 6
#define PWRSV 5
#define VRPS 3

//ECON1
#define TXRST 7
#define RXRST 6
#define DMAST 5
#define CSUMEN 4
#define TXRTS 3
#define RXEN 2
#define BSEL1 1
#define BSEL0 0

//MICMD
#define MIISCAN 1
#define MIIRD 0

//MISTAT
#define NVALID 2
#define SCAN 1
#define BUSY 0

//ERXFCON
#define UCEN 7
#define ANDOR 6
#define CRCEN 5
#define PMEN 4
#define MPEN 3
#define HTEN 2
#define MCEN 1
#define BCEN 0

//MACON1
#define TXPAUS 3
#define RXPAUS 2
#define PASSALL 1
#define MARXEN 0

//MACON3
#define PADCFG2 7
#define PADCFG1 6
#define PADCFG0 5
#define TXCRCEN 4
#define PHDREN 3
#define HFRMEN 2
#define FRMLNEN 1
#define FULDPX 0

//MACON4
#define DEFER 6
#define BPEN 5
#define NOBKOFF 4

//EIR
#define TXIF 3


//PHY-REGISTER
#define PHCON1 0x00
#define PHSTAT1 0x01
#define PHID1 0x02
#define PHID2 0x03
#define PHCON2 0x10
#define PHSTAT2 0x11
#define PHIE 0x12
#define PHIR 0x13
#define PHLCON 0x14

//PHSTAT1
#define PFDPX 12
#define PFHPX 11
#define LLSTAT 2
#define JBSTAT 1

//PHSTAT2
#define TXSTAT 13
#define RXSTAT 12
#define COLSTAT 11
#define LSTAT 10
#define DPXSTAT 9
#define PLRITY 5

//PHCON1
#define PRST 15
#define PLOOPBK 14
#define PPWRSV 11
#define PDPXMD 8

//PHCON2
#define FRCLNK 14
#define TXDIS 13
#define JABBER 10
#define HDLDIS 8

#endif
