;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

; RS - P2.0
; RW - P2.1
; E  - P2.2

; D0 - P3.0
; D1 - P3.1
; D2 - P3.2
; D3 - P1.3 P3.3 is broken
; D4 - P3.4
; D5 - P3.5
; D6 - P3.6
; D7 - P3.7

main:

	mov #heart, R4
	mov.b #0, R6

	bic #LOCKLPM5, &PM5CTL0 ; allow pins to be changed... the horrors this line of code has caused me...
	bis.b #BIT0, &P1DIR ; set P1.0 to output
	bis.b #BIT0, &P1OUT ; set P1.0 on

	bis #TBCLR, &TB0CTL ; clear timer stuff
	bis	#TBSSEL__SMCLK,	&TB0CTL ; select SMCLK
	bis	#MC__CONTINUOUS, &TB0CTL ; make it so it counts forever
	bis #CNTL_1, &TB0CTL ; make it 12 bit. only counts to 4096
	bis	#TBIE,	&TB0CTL ; enable interrupt when overflow
	bic	#TBIFG,	&TB0CTL ; clear interrupt flag
	nop
	bis #GIE, SR ; enable maskable interrupts
	nop
	; this timer is for delay

	bis.b #BIT3, &P1DIR ; set P1.3 to output
	bis.b #0FFh, &P3DIR ; set data bits to output
	bis.b #07h, &P2DIR ; set control bits to ouput

	mov #2712, Cycles ; set to delay for 15k cycles (15000%4096)
	mov #3, Loops ; set to delay for 15k cycles (15000/4096) (integer part)
	mov.b #1, delaying
	mov #0, &TB0R ; reset timer to 0
	call #delay ; let it rip >:)

	mov.b #0, mask ; set RS to low

	mov.b #38h, payload ; instruction to enable 8 bit mode
	call #send_payload

	mov.b #01h, payload ; instruction to clear screen
	call #send_payload

	mov.b #00001100b, payload ; instruction to turn screen on
	call #send_payload

	mov.b #00000110b, payload ; instruction to set entry mode
	call #send_payload

	mov.b #01011000b, payload ; instruction to set CGRAM address
	call #send_payload

	mov.b #BIT0, mask ; set RS to high

send_custom_character:

	mov.b @R4+, R5

	mov.b R5, payload
	call #send_payload

	inc.b R6

	cmp.b #8, R6

	jnz send_custom_character

	mov #message, R4

	mov.b #0, R6

	mov.b #0, mask ; set RS to low

	mov.b #10000000b, payload ; instruction to move to first line
	call #send_payload

	mov.b #BIT0, mask ; set RS to high

send_sentence:

	mov.b @R4+, R5

	tst.b R5

	jz end

	mov.b R5, payload
	call #send_payload

	inc.b R6

	cmp.b #16, R6

	jz new_line

	jmp send_sentence

new_line:

	mov.b #0, mask ; set RS to low

	mov.b #11000000b, payload ; instruction to move to second line
	call #send_payload

    mov.b #BIT0, mask ; set RS to high

	mov.b #0, R6

	jmp send_sentence

send_payload:

	clr.b &P2OUT ; clear control bits
	bis.b mask, &P2OUT ; set RS
	bic.b #BIT1, &P2OUT ; set R/W to low

	call #delay_4096

	call #set_payload ; write payload

	call #delay_4096

	bis.b #BIT2, &P2OUT ; set E to high to enable writing

	call #delay_4096

	bic.b #BIT2, &P2OUT ; set E to low to end writing

	call #delay_4096

	bic.b #BIT3, &P1OUT ; clear data bits
	clr.b &P3OUT ; clear data bits
	clr.b &P2OUT ; clear control bits

	call #delay_4096

	ret

set_payload: ;P3.3 is broken so we are replacing it with P1.3


	mov.b payload, &P3OUT ; move payload to &P3OUT
	and.b #BIT3, payload ; pull out the third bit of payload
	bis.b payload, &P1OUT ; set the third bit of payload to &P1OUT
	mov.b &P3OUT, payload

	ret

delay_4096:

	mov #0, Cycles ; set to delay for 4096 cycles (4000%4096)
	mov #1, Loops ; set to delay for 4096 cycles (4000/4096) (integer part)
	mov.b #1, delaying
	mov #0, &TB0R ; reset timer to 0
	call #delay ; let it rip >:)

	ret

delay:

	cmp Loops, Overflow

	jne delay

	cmp &TB0R, Cycles

	jge delay

	mov.b #0, delaying

	mov #0, Overflow

	ret

overflow:

	bic #TBIFG,	&TB0CTL

	tst.b delaying
	jz overflow_2

	inc	Overflow

	reti

overflow_2:

	reti


end:

	bic.b #BIT0, &P1OUT ; set P1.0 off

loop:

	jmp loop

	nop

	.data
	.retain


Cycles	.short 0 ; max 4096
Loops	.short 0
Overflow .short 0
delaying .byte 0

payload .byte 0
mask .byte 0

message:
    .string " Will You Be My  "
    .byte 0x03
    .string " Valentine? "
	.byte 0x03
	.byte 0x00

heart .byte 00000000b, 00001010b, 00011111b, 00011111b, 00011111b, 00001110b, 00000100b, 00000000b


; 0 0 0 0 0
; 0 1 0 1 0
; 1 1 1 1 1
; 1 1 1 1 1
; 1 1 1 1 1
; 0 1 1 1 0
; 0 0 1 0 0
; 0 0 0 0 0


;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET

            .sect	".int42"
            .short	overflow
