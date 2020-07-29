/*
This code receives raw audio-data from the specified LAN-Interface and writes it to stdout.
This code needs root-privileges because we are listening for raw Ethernet II-packets.

This is for Linux only. Tested on Debian 10.

Quick and dirty but works fine. If you change MAC-adresses or Ethertype or ... in the assembly-code you need to adjust this code too.

compile with gcc receive.c -o receive

Bug: recv() waits for data, if you Ctrl+C while there is no data the program will not stop.

(c) 2020 by kitten_nb_five

AGPL v3 or later

THIS CODE COMES WITHOUT ANY WARRANTY!
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <net/ethernet.h>
#include <signal.h>

#include "my_err.h"

#define SZ_BUF 512

volatile int run=1;

void sigint(int sig)
{
	(void)sig;
	run=0;
}

void usage(void)
{
	printf("./receive $interface > $file OR ./receive $interface | $other_tool\n");
	printf("try ./receive $interface | sox -t raw -b 24 -B -c 1 -e signed-integer -r 31.25k - out.wav\n");
	exit(0);
}

int main(int argc, char *argv[])
{
	int sock;
	unsigned char buf[SZ_BUF];
	int rx_size;

	if(argc!=2)
		usage();

	if(geteuid()!=0)
	{
		fprintf(stderr, "WARNING: You are not root. This program will probably fail.\n");
	}
	
	signal(SIGINT, &sigint);
	
	sock=socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
	if(sock<0)
		ERR(1, "could not open socket");
	
	if(setsockopt(sock, SOL_SOCKET, SO_BINDTODEVICE, argv[1], IFNAMSIZ)<0)
		ERR(1, "could not bind to device");
	
	fprintf(stderr, "listening on %s\n", argv[1]);

	while(run)
	{
		rx_size=recv(sock, buf, SZ_BUF, 0); //blocking read
						//MAC dest, MAC from, Ethertype
		if(!memcmp(buf, "\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00", 14))
			fwrite(buf+14, rx_size-14-2, 1, stdout); //don't write header (14) and checksum (2)
	}
	
	close(sock);
	
	fprintf(stderr, "\nBye.\n");
	
	return 0;
}
