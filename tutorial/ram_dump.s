

PORTB = $6000
PORTA = $6001


DDRB = $6002
DDRA = $6003

PCR = $600c
IFR = $600d
IER = $600e


E  = %01000000
RW = %00100000
RS = %00010000

RED_LED = %10000000
GREEN_LED = %01000000 



BASE_ADDRESS = $0000  ; find a way to increment this via i/o buttions

DUMP_POINTER = $00


  .org $8000

reset:
  ldx #$ff
  txs
  
  lda #$92    ; enable CA1 & CB1 interrupts
  sta IER

  lda #$00    ; set edge direction for interrupt inputs to negative-going
  sta PCR
  cli         ; enable CPU Interrupts

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11000000 ; Set high pins on port A to output for LEDs
  sta DDRA

  jsr lcd_init

  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction
 

  lda #<BASE_ADDRESS
  sta DUMP_POINTER
  lda #>BASE_ADDRESS
  sta DUMP_POINTER + 1

  jsr new_address

 
end:		; loop to delay end
  lda #$00
  sta PORTA	; green off

  lda #RED_LED
  sta PORTA
  jmp end

new_address:
  
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  ldy #$00
  ldx #$00

line1:
  lda #"$"
  jsr print_char
  lda DUMP_POINTER + 1
  jsr bintohex
  lda DUMP_POINTER
  jsr bintohex
	
  
new_line:
  lda #%10101001
  jsr lcd_instruction

line2:
  
  lda (DUMP_POINTER),y
  jsr bintohex
  iny
  cpy #$08
  bne line2
  rts


bintohex:
 	pha
	lsr
	lsr
	lsr
	lsr
	tax
	lda hexascii,x
	jsr print_char
	pla
	and #$0f
	tax
	lda hexascii,x
	jsr print_char
	rts		
  
lcd_wait:
  pha
  lda #%11110000  ; LCD data is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcdbusy

  lda #RW
  sta PORTB
  lda #%11111111  ; LCD data is output
  sta DDRB
  pla
  rts

lcd_init:
  lda #%00000010 ; Set 4-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB
  rts

lcd_instruction:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  rts

print_char:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  pla
  and #%00001111  ; Send low 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  rts


hexascii: .byte "0123456789abcdef"

increment_address:

  clc
  lda DUMP_POINTER
  adc #$8
  sta DUMP_POINTER
  bcc ok
  inc DUMP_POINTER + 1
ok:
  rts

nmi:

irq:

; preserve registers
  pha
  txa
  pha
  tya
  pha

; DO THE INTERRUPT STUFF
; it will only be due to CA1 at the moment
; for more control we need to read IFR and determine the source (CA1, CA2, Timer etc)
; then if necessary read the PORT's inputs to determine which PORT bit was pulled low
; as well as CA1
  lda #$00
  sta PORTA
  lda #GREEN_LED
  sta PORTA

  jsr increment_address
  jsr new_address


exit_irq:

; de-bounce delay before resetting interrupt
  ldy #$ff ; tweak the count-down to optimise debounce
  ldx #$ff ;
delay:
 dex
  bne delay
  dey
  bne delay

  bit PORTB     ; clear VIA interrupt by reading from PORTB
  
  lda #$00
  sta PORTA

; restore registers
  pla
  tay
  pla
  tax
  pla

  rti


; Reset/IRQ vectors
  .org $fffa
  .word nmi
  .word reset
  .word irq
