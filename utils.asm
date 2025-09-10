#ifndef __utils__
#define __utils__ 1

.include "const.inc"
.include "ascii.inc"

; Explicitly managing program memory
.org PROGRAM_UTILS

; MACROS
.macro push2 ; (r_data1, r_data2)
	; Mainly used for X, Y, Z registers
	push @0
	push @1
.endmacro


.macro pop2 ; (r_data1, r_data2)
	; Mainly used for X, Y, Z registers
	pop @0
	pop @1
.endmacro


.macro push_sreg ; (r_temp)
	; Push and clear SREG
	; Modifies: r_temp (push it before SREG)
	in @0, SREG
	push @0
	clr @0
	out SREG, @0
.endmacro


.macro pop_sreg ; (r_temp)
	; Pop and restore SREG
	; Modifies: r_temp (pop it after SREG)
	pop @0
	out SREG, @0
.endmacro


.macro clear_sreg
	; Initialize (clear) status register
	; This macro doesn't modify data in regs
	push r16
	clr r16
	out SREG, r16
	pop r16
.endmacro


.macro ldxdptr ; (p_address)
	; Dereference pointer and load in X
	; Modifies: X
	.set p_address = @0
	lds XH, p_address
	lds XL, p_address+1
.endmacro


.macro stxdptr ; (pp_address)
	; Store pointer from X in RAM: p_address at &p_address
	.set pp_address = @0
	sts pp_address, XH
	sts pp_address+1, XL
.endmacro


.macro ldx16 ; (p_value)
	; Load 16-bit value to X (pointer value)
	; Modifies: X
	ldi XH, high(@0)
	ldi XL, low(@0)
.endmacro


.macro ldz16pm ; (p_value_pm)
	; Load 16-bit value to Z (pointer value)
	; Note 1: Program memory (flash) consists of 16-bit words
	; Note 2: (Byte address) = (Word address) * 2
	; Note 3: Only Z register can be used to address program memory
	; Modifies: Z
	ldi ZH, high(@0 * 2)
	ldi ZL, low(@0 * 2)
.endmacro


.macro digit2char ; (r_data)
	; Rd = Rd + '0'
	; Modifies: r_data (@0)
	push r31
	ldi r31, CHAR_0		; '0-9' + '0'
	add @0, r31
	pop r31
.endmacro


.macro char2digit ; (r_data)
	; Rd = Rd - '0'
	; Modifies: r_data (@0)
	push r31
	ldi r31, CHAR_0
	sub @0, r31
	pop r31
.endmacro


.macro uart_send ; (r_data)
	; Send data with UART
	__wait_udr_empty:
		sbis UCSRA, UDRE
		rjmp __wait_udr_empty
	out UDR, @0
.endmacro


.macro uart_sendch ; (c_char)
	; Send char with UART
	;.set c_char = @0
	push r16
	ldi r16, @0      ;c_char
	uart_send r16
	pop r16
	ret
.endmacro


.macro uart_sendnum ; (r_num)
	; UNFINISHED
	; bin -> dec -> dec digits -> uart_sendch "calls"
	push @0
	
	; Code here
	
	pop @0
.endmacro


; Maybe move all of that to subroutines
.macro check_array_ovf ; (p_array, c_size)
	; Check pointer overflow for array with size
	; Modifies: X (if overflow)
	.set p_array = @0
	.set c_size = @1
	
	; If (X < p_array + c_size): do nothing
	cpi XH, high(p_array + c_size)
	brlo _no_array_overflow
	cpi XL, low(p_array + c_size)
	brlo _no_array_overflow
	
	; Else: move pointer to start of buffer
		ldi XH, high(p_array)
		ldi XL, low(p_array)
	
	_no_array_overflow:
.endmacro


.macro check_array_underf ; (p_array, c_size)
	; Check pointer underflow for array with size
	; NOTE: consider --X
	.set p_array = @0
	.set c_size = @1
	
	; If (X > p_array): do nothing
	cpi XH, high(p_array+1)
	brsh _no_array_underflow
	cpi XL, low(p_array+1)
	brsh _no_array_underflow
	
	; Else: move pointer to end of buffer
		ldi XH, high(p_array+c_size)
		ldi XL, low(p_array+c_size)
		
	_no_array_underflow:
.endmacro


.macro uart_print_pm
	; Print string from program memory
	; Modifies: Z
	; Note: Z register must be prepared
	push r16

	_uart_print_pm_loop:
		lpm r16, Z+
		cpi r16, NULL
		breq _uart_print_pm_exit
		uart_send r16
		rjmp _uart_print_pm_loop
	
	_uart_print_pm_exit:

	pop r16
.endmacro


.macro clear_array ; (p_array, c_size)
	; Set all array elements to zeros
	; Value is taken from r16
	.set p_array = @0
	.set c_size = @1
	
	.def l_data = r16
	.def l_counter = r17
	
	push l_data
	push l_counter
	
	clr l_data
	clr l_counter
	ldi XH, high(p_array)
	ldi XL, low(p_array)
	_clear_array_loop:
		st X+, r16
		inc r17
		cpi r17, c_size
		brlo _clear_array_loop
		
	pop l_counter
	pop l_data
	.undef l_data
	.undef l_counter
	;ret
.endmacro


; UNUSED
; NOTE: could be changed into modByPow2 macro
.macro mod8 ; (r_data)
	; Rd = Rd % 8
	; Modifies: r_data (@0)
	.equ _mod8mask = 0b0000_0111
	andi @0, _mod8mask
.ENDMACRO


.macro mod4 ; (r_data)
	; Rd = Rd % 4
	; Modifies: @0 (r_data)
	.equ _mod4mask = 0b0000_0011
	andi @0, _mod4mask
.endmacro


.macro mod32 ; (r_data)
	; Rd = Rd % 32
	.equ _mod32mask = 0b0001_1111
	andi @0, _mod32mask
.endmacro


#endif

