<b>WHAT DOES THIS DO?</b><br>
This code makes an ATmega328P receive data from an I2S-MEMS-microphone and transmits it over LAN using an ENC28J60.

<b>WHY???</b><br>
Why not? I wanted to prove that you can receive I2S with an 8 bit AVR.

<b>LANGUAGE?</b><br>
Assembly for GNU `as` called trough GNU `avr-gcc`. See below.

<b>LICENCE?</b><br>
AGPL v3 or later and NO WARRANTY!

<b>WHAT THE HECK IS "I2S"?</b><br>
from Wikipedia: "I²S (Inter-IC Sound), pronounced eye-squared-ess, is an electrical serial bus interface standard used for connecting digital audio devices together."
Not to be confused with I2C, thats completly unrelated.

<b>WHAT IS "MEMS"?</b><br>
Microelectromechanical systems. Ask Wikipedia.

<b>WHAT IS "AVR"?</b><br>
I think you are at the wrong place here...

<b>DOES IT USE ARDUINO?</b><br>
No. This is plain assembly written from scratch.

<b>PARTS LIST?</b><br>
The processor is an ATmega328P running on 3,3V with a 20MHz crystal - thats out of spec but works fine for me - YMMV.
The microphone is an INMP441 on a breakoutboard from Aliexpress. Other Mics should work just fine if the resolution is 24 bits or less.
The connection to LAN is made by an ENC28J60 (breakoutboard from Aliexpress too).

<b>SPECIFICATIONS?</b><br>
The MEMS-microphone spits out 24 bits of data for each sample.
The Masterclock for the Mic is 2MHz. WordSelect and so samplerate is 2MHz/64=31.25kHz. This gives the full frequency-response of the Mic from 60Hz to 15kHz.
The data is buffered and send out to LAN as raw Ethernet II-packets with 252 bytes (84 samples) of payload each (+2 bytes checksum added by the ENC). Currently the data is send from MAC 00:00:00:00:00:00 to Broadcast (FF:FF:FF:FF:FF:FF) but this could be changed. Ethertype is set to 0x0000, could also be changed.
The audio is 24 bit signed PCM BIG ENDIAN @31.25kHz.

<b>LIMITATIONS?</b><br>
You can only receive data from ONE Mic/I2S-slave == mono.
The code samples while WordSelect is LOW, data that arrives while WordSelect is HIGH is ignored.
I don't think stereo is possible with the limited ressources of an AVR, feel free to prove me wrong.
There are no verification if LAN is up, a transmit was sucessful and so on because there is no time for this(?) and i wanted to keep it as simple as possible. Assembly is tedious business.

<b>PINOUT?</b><br>
SPI-Interface connected to ENC28J60 with SS on PB2
USART used as SPI-Master connected to Mic (PD0, PD1, PD4)	
20MHz crystal on the standard pins
Power is 3,3V with the usual decoupling caps and 10k pullup on RESET.
For the INMP441 you need to connect L/R to GND.

<b>SCHEMATIC?</b><br>
None. See above, thats all you need.

<b>FUSES?</b><br>
Fuses are set for crystal-clock 20MHz.
E:FF H:D9 L:E7

<b>HOW TO COMPILE/FLASH?</b><br>
compile/assemble with `avr-gcc -mmcu=atmega328p -o avr.elf main.S`
flash using your favorite tool, for example `avrdude -p m328p -c usbasp-clone -U flash:w:avr.elf`

<b>HOW TO RECEIVE THE DATA?</b><br>
On Linux you can use receive.c and e.g. `sox` to convert the raw data to a wav-file.
On other systems you need something to listen for raw Ethernet II-packets, extract the payload and write it to a file or pipe it somewhere.

<b>HOW DOES IT WORK? / I WANT DETAILS!</b><br>
I use the USART of the AVR in SPI-mode to receive the actual data. The important thing is that this peripheral has double-buffering, so it allows *continuous* data input/output. I use the SPI-clock as I2S-clock and MOSI as WordSelect by sending 0x00 (for WS=0) or 0xff (for WS=1). By sending 4 bytes each i get the right frequency == Masterclock/64. I use MISO for sampling the data (with a shift because I2S-data begins on second clock-cycle only). This method works but the USART must be read/written quite often. I had no luck with interrupts but this was still with C-code (and ISR_NAKED however).

For the link to the ENC28J60 i use the standard SPI-interface, nothing special here. The clock is set to maximum (SPI2X is set) to make the communication as fast as possible and also because the ENC28J60 has a silicon bug and needs an SPI-clock of 8MHz or more to avoid some data corruption (read the Errata!).

The communication with the ENC28J60 is divided into small parts to fit into the timeslots between two USART-transfers.

The adresses for TX/RX-buffer and size inside the ENC28J60 are hardcoded. The RX-buffer must start at 0x00 because of a silicon bug (again!). There is plenty of space left to add stuff, the bottleneck is processing power / speed of the AVR.

Reception on the ENC28J60 is disabled.

The Packet Control Byte and the Ethernet-Header are written only once as they stay in memory of the ENC.

I use two buffers of 256 bytes each, one for current I2S-RX and one for LAN-TX. Size and locations were choosen so i can switch buffers using a simple XOR on the high-byte of the address pointer.
