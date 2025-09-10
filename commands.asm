#ifndef __commands__
#define __commands__ 1

.include "ascii.inc"
.include "const.inc"

.org PROGRAM_COMMANDS

_command_strings:
	; NOTE: '/' (start of command) is ommited for replaceability
	p_cmdDump	: .DB "dump", RETURN, 0			; dump buffer
	p_cmdHead	: .DB "head", RETURN, 0			; send buffer head
	p_cmdTail	: .DB "tail", RETURN, 0			; send buffer tail
	p_cmdAddr	: .DB "addr", RETURN, 0			; send buffer address
	p_cmdClear	: .DB "clear", RETURN, 0, 0		; clear terminal (or set all buffer to 0)
		
	; Command messages
	p_msgDump	: .DB "DUMP:", 0
	p_msgHead	: .DB "HEAD:", 0
	p_msgTail	: .DB "TAIL:", 0
	p_msgAddr	: .DB "ADDRESS:", 0, 0
	p_msgClear	: .DB "CLEAR:", 0, 0
	
	
.macro wcall_print_message ; (p_message)
	; Prepare pointer for uart_print_pm
	push2 ZH, ZL
	ldz16pm @0
	rcall print_message
	pop2 ZL, ZH
.endmacro


print_message:
	uart_print_pm
	uart_sendch RETURN
	ret


COMMAND_DUMP:
	wcall_print_message p_msgDump
	; TODO: code
	nop
	ret
	

COMMAND_HEAD:
	wcall_print_message p_msgHead
	; TODO: code
	nop
	ret
	
	
COMMAND_TAIL:
	wcall_print_message p_msgTail
	; TODO: code
	nop
	ret
	
	
COMMAND_ADDRESS:
	wcall_print_message p_msgAddr
	; TODO: code
	nop
	ret
	
	
COMMAND_CLEAR:
	wcall_print_message p_msgClear
	clear_array p_buffer, size_buffer
	ret
	
	
#endif
