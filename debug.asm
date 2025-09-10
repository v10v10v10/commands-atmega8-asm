#ifndef __debug__
#define __debug__ 1


.org PROGRAM_DEBUG
_debug_mem_mngmt:
	ldi r16, 0x01
	mov r0, r16
	ldi r16, 0x02
	mov r1, r16
	ldi r16, 0x03
	mov r2, r16
	ldi r16, 0x04
	mov r3, r16
	ldi r16, 0x05
	mov r4, r16
	ldi r16, 0x06
	mov r5, r16
	ldi r16, 0x07
	mov r6, r16
	ldi r16, 0x08
	mov r7, r16
	ldi r16, 0x09
	mov r8, r16
	ldi r16, 0x10
	mov r9, r16
	ldi r16, 0x11
	mov r10, r16
	ldi r16, 0x12
	mov r11, r16
	ldi r16, 0x13
	mov r12, r16
	ldi r16, 0x14
	mov r13, r16
	ldi r16, 0x15
	mov r14, r16
	ldi r16, 0x16
	mov r15, r16
	
	ldi r16, 0x17
	ldi r17, 0x18
	ldi r18, 0x19
	ldi r19, 0x20
	ldi r20, 0x21
	ldi r21, 0x22
	ldi r22, 0x23
	ldi r23, 0x24
	ldi r24, 0x25
	ldi r25, 0x26
	ldi r26, 0x27
	ldi r27, 0x28
	ldi r28, 0x29
	ldi r29, 0x30
	ldi r30, 0x31
	ldi r31, 0x32
	ret

	
#endif
