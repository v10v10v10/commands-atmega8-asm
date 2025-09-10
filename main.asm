;.device ATmega8

; Microcontroller header file
.include "m8def.inc"

; Header files
.include "ascii.inc"			; ASCII-table definitions
.include "const.inc"			; Constant names

; Source code files
.include "utils.asm"			; Utility macros and subroutines
.include "commands.asm"			; Command subroutines
.include "debug.asm"			; Test memory management


.DSEG
	; NOTE: "Double" pointers are used here to store pointers in RAM
	p_buffer	: .byte SIZE_BUFFER		; Reserve RAM for buffer
	pp_write	: .byte 2				; Store write pointer at &p_write
	pp_read		: .byte 2				; Store read pointer at &p_read
	p_flags		: .byte 1				; Array of 8 command flags at &p_flags
	p_seqlen	: .byte 1				; Len of parsed sequence at &p_seqlen
	p_lastpc	: .byte 2				; UNUSED, MAYBE FOR UDRIE
	
	
.CSEG
	; Interrupt vectors table
	.org 0x0000 rjmp INIT
	.org URXCaddr rjmp UART_RXC_ISR
	;.org UDREaddr rjmp UART_UDRE_ISR
	;.org UTXCaddr rjmp UART_TXC_ISR
	
	
.org PROGRAM_MAIN
INIT:
	cli
	; Initialize stack pointer
	ldi r16, high(RAMEND)
	out SPH, r16
	ldi r16, low(RAMEND)
	out SPL, r16
	
	; Initialize used I/O ports
	ldi r16, (1 << 1)				; PD1: output (1), PD0: input (0)
	out DDRD, r16					
	ldi r16, 0b1111_1110			; Enabling pull-up resistors
	out PORTD, r16					
	
	; Initialize other I/O ports
	clr r16
	out DDRB, r16
	out DDRC, r16
	ser r16
	out PORTB, r16
	out PORTC, r16
	
	
	; Initialize UART
	; TODO?: add TXCIE and UDRIE
	; Enable receiver, transmitter, interrupt on receive and transmit
	ldi r16, (1 << RXEN) | (1 << TXEN) | (1 << RXCIE)
	out UCSRB, r16
	
	; Set frame format: 8-bit, no parity, falling edge
	ldi r16, (1 << URSEL) | (1 << UCSZ1) | (1 << UCSZ0)
	out UCSRC, r16
	
	; Set UBRR according to CLK and BAUD rates
	.equ UBRR16 = CLOCK_RATE / (16 * BAUD_RATE - 1)
	ldi r16, high(UBRR16)
	out UBRRH, r16
	ldi r16, low(UBRR16)
	out UBRRL, r16
	
	
	; Initialize used RAM
	clr r16
	sts p_seqlen, r16
	sts p_flags, r16
	
	; *pp_write = p_buffer, *pp_read = p_buffer
	ldi r16, high(p_buffer)
	ldi r17, low(p_buffer)
	sts pp_write, r16
	sts pp_write+1, r17
	sts pp_read, r16
	sts pp_read+1, r17
	clear_array p_buffer, size_buffer	; Initialize buffer with zeros
	
	
	rcall _debug_mem_mngmt				; OPTIONAL: load values in r0-r31
	clear_sreg							; Clear (initialize) status register
	sei									; Enable global interrupts
	
	
MAIN:
	; Main program
	nop
	rjmp MAIN
	
	
UART_RXC_ISR:
	; NOTE: .defs give too many warnings
	push r16					; Used for storing read data
	push r17
	push_sreg r16
	
	
	rcall WRITE_BUFFER
	rcall CHECK_LAST_INPUT
	
	; If (FLAG START) is FALSE: return
	sbrs r17, FLAG_START
		rjmp _uart_rxc_isr_return
		
	; Else:
		rcall CHECK_SEQUENCE_LENGTH
		cpi r17, (1 << FLAG_START) | (1 << FLAG_END)
		brne _uart_rxc_isr_return
		; If (FLAG END) AND (FLAG START) is TRUE:
			rcall PARSE_STRING		
			clr r16					
			sts p_flags, r16		; Clear flags after parsing
	
	_uart_rxc_isr_return:
	pop_sreg r16
	pop r17
	pop r16
	reti
	

WRITE_BUFFER:
	; Write to buffer subroutine
	; TODO: add backspace functionality
	; Modifies: r16
	.def r_data = r16
	push2 XH, XL
	
	; Subroutine
	in r_data, UDR					; Read from UDR (also clears RXC flag)
	cpi r_data, BACKSPACE			; Skip writing backspace (?)
	breq _write_buffer_return
	
	ldxdptr pp_write				; X = &p_write
	st X+, r_data					; *(X++) = data
	
	; Circling the buffer and checking for overflow
	check_array_ovf p_buffer, size_buffer
	
	; Store X at &p_write
	stxdptr pp_write
	; Subroutine end
	
	_write_buffer_return:
	pop2 XL, XH
	.undef r_data
	ret
	
	
CHECK_LAST_INPUT:
	; Check last input subroutine
	; Modifies: r17 (r_flags)
	.def r_data = r16
	.def r_flags = r17
	
	; Subroutine
	lds r_flags, p_flags				; flags = *p_flags
	;sbrc r_flags, FLAG_START			; If (FLAG START):
	;	rjmp _check_seq_end				;	JUMP to check (END OF COMMAND)
	
	
	; Check if (LAST INPUT) is (START OF COMMAND)
	_check_seq_start:
	cpi r_data, SLASH
	brne _check_seq_end
		; If (LAST INPUT) is (START OF COMMAND):
		push2 XH, XL
		ldi r_flags, (1 << FLAG_START)	; flag_start = True
		ldxdptr pp_write				; X = p_write
		stxdptr pp_read					; p_read = X
		ori r_flags, (1 << FLAG_UPDATE) ; p_read updated flag
		pop2 XL, XH						
		rjmp _check_seq_exit			; return
	
	
	; Check if (LAST INPUT) is (END OF COMMAND)
	_check_seq_end:
	cpi r_data, RETURN
	brne _check_seq_exit
		; If (LAST INPUT) is (END OF COMMAND):
		ori r_flags, (1 << FLAG_END)	; flag_end = True
		rjmp _check_seq_exit			; return
	
	
	; Exit (return) from subroutine
	_check_seq_exit:
	sts p_flags, r_flags
	
	; Subroutine end
	.undef r_data
	.undef r_flags
	ret


CHECK_SEQUENCE_LENGTH:
	; Check length of sequence between start symbol and current symbol
	; Modifies: r17 (r_flags)
	.def r_seqlen = r16
	.def r_flags = r17
	push r_seqlen
	
	lds r_seqlen, p_seqlen 		; seqlen++ = *p_seqlen
	inc r_seqlen
	
	sbrc r_flags, FLAG_UPDATE	; If (FLAG UPDATE)
		rjmp _seq_len_reset		;	reset seqlen
	
	
	; If (FLAG END): r_seqlen = 0, return
	cpi r_flags, (1 << FLAG_END) | (1 << FLAG_START)
	brne _seq_len_compare
		_seq_len_reset:
		clr r_seqlen
		andi r_flags, (0 << FLAG_UPDATE) | (1 << FLAG_START) | (1 << FLAG_END)
		rjmp _seq_len_return
	
	
	_seq_len_compare:
	cpi r_seqlen, size_string	; (seqlen < size_string)
	brlo _seq_len_return
	; If (seqlen >= size_string) OR (FLAG END):
		clr r_seqlen			; r_seqlen = 0
		clr r_flags
		sts p_flags, r_flags	; *p_flags = 0
	
	
	_seq_len_return:
	sts p_seqlen, r_seqlen		; Store seqlen at p_seqlen
	;
	
	pop r_seqlen
	.undef r_seqlen
	.undef r_flags
	ret



; Wrapper / parametrized calls
.macro wcall_strcmp_zx ; (b_flag, p_array, c_size)
	.set p_string = @1
	.set c_size = @2
	
	rcall strcmp_zx
.endmacro


.macro wcall_parse_string ; (p_command, command_call)
	.set p_command = @0
	.set command_call = @1
	
	ldxdptr pp_read
	ldz16pm p_command
	wcall_strcmp_zx b_flag, p_buffer, size_buffer
	
	cpi b_flag, 0xFF
	brne _wcall_parse_string_exit
		rcall command_call
	
	_wcall_parse_string_exit:
.endmacro



PARSE_STRING:
	; Parse sequence subroutine
	; And see if it matches any commands
	.def r_command = r16
	.def r_string = r17
	.def b_flag = r18
	
	push b_flag
	push2 XH, XL
	push2 ZH, ZL
	
	
	wcall_parse_string p_cmdDump, COMMAND_DUMP
	wcall_parse_string p_cmdHead, COMMAND_HEAD
	wcall_parse_string p_cmdTail, COMMAND_TAIL
	wcall_parse_string p_cmdAddr, COMMAND_ADDRESS
	wcall_parse_string p_cmdClear, COMMAND_CLEAR
	
	_parse_string_exit:
	
	
	pop2 ZL, ZH
	pop2 XL, XH
	pop b_flag
	
	.undef r_command
	.undef r_string
	.undef b_flag
	ret


strcmp_zx: ; (b_flag, p_array, c_size)
	; r16 	<- command
	; r17 	<- string
	; r18 	<- flag: returns 0xFF if (string == command)
	; Z		<- pointer (program memory)
	; X		<- pointer (data memory)
	; Modifies: r18, Z, X
	
	; Compare string from program memory to string in RAM
	; p_array, c_size are required to prevent array overflow
	push r16	; r_command
	push r17	; r_string
	
	;.set p_string = @1
	;.set c_size = @2
	_strcmp_zx_loop:
		lpm r16, Z+
		ld r17, X+
		check_array_ovf p_string, c_size
		
		cpi r16, NULL
		breq _strcmp_zx_return
			; if command != '\0'
			cp r16, r17
			brne _strcmp_zx_return
			rjmp _strcmp_zx_loop
		
	_strcmp_zx_return:
		ldi r17, 0xFF
		eor r16, r17
		mov r18, r16
	
	
	pop r17
	pop r16
	
	ret
