.org $fffa
  .word nmi
  .word reset
  .word irq
; VIA Addressing
PORTB = $6000
PORTA = $6001

DDRB = $6002
DDRA = $6003

PCR = $600c
IFR = $600d
IER = $600e

; LCD control
E  = %01000000
RW = %00100000
RS = %00010000

; LEDs on port A
RED_LED = %10000000
GREEN_LED = %01000000

  .org $8000

reset:
  ldx #$ff  ; initialize stack
  txs       ;
  
  lda #$92  ; enable CA1 & CB1 interrupts
  sta IER   ;
  lda #$00  ; Set edge direction for inputs to negative-going
  sta PCR
  cli       ; enable interrupts

  lda #%11111111 ; Set all pins on VIA port B to output
  sta DDRB
  lda #%11000000 ; Set 2 MSB pins on VIA port A to output (for status LEDs) otherwise set as inputs
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

  ldx #0


print1:
  lda message1,x
  beq print2
  jsr print_char
  inx
  jmp print1
  
print2:
  lda #%10101001
  jsr lcd_instruction
  ldx #0
line2:
  lda message2,x
  beq loop
  jsr print_char
  inx
  jmp line2

loop:
  lda #RED_LED
  sta PORTA
  jmp loop

message1: .asciiz "Shed-o-tron II "
message2: .asciiz "* * 22/8/22 * * "

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
  lda PORTA
  
  eor #GREEN_LED
  sta PORTA

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
