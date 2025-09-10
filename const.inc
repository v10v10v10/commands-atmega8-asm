#ifndef __const__
#define __const__ 1


; Program memory constants (word addresses)
; Note: Byte address = (Word address) * 2
.equ PROGRAM_MAIN			= 0x0018 / 2
.equ PROGRAM_INIT			= 0x0200 / 2
.equ PROGRAM_UTILS			= 0x0400 / 2
.equ PROGRAM_COMMANDS		= 0x0800 / 2
.equ PROGRAM_DEBUG			= 0x1000 / 2


; Microcontroller parameters
.equ CLOCK_RATE = 8_000_000
.equ BAUD_RATE = 9600


; Buffer parameters
.equ SIZE_BUFFER	= 0x20
.equ SLICE_BUFFER	= (SIZE_BUFFER/2) < 5 ? (SIZE_BUFFER/2) : 5


; Bits of command flags
.equ SIZE_STRING 	= 7
.equ FLAG_START		= 0
.equ FLAG_END		= 1
.equ FLAG_UPDATE	= 2


#endif
