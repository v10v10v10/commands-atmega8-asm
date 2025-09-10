For this project source code for utils and helpers should be re-organized between subroutines and macros.\
At this stage the project has desired functionality. However to finish it properly, interrupt handling
must be modified for transmitting (TXCIE) and empty UDR (UDRIE) to make the "commands subroutines" not
stall "the main loop" of the chip.\
Also it is important to point out that "backspace" functionality wasn't fully implemented,
but it's pretty easy to add-in.\
Commands and their functionality was left blank intentionally and can be customized in any desired way,
with consideration of notes above.


### Description
Input characters from transmitter are written to buffer during an interrupt.
During ISR the input is being analyzed on having special symbols (start of command, end of command).
If the input between those symbols matches one of commands, then the corresponding subroutine is called.