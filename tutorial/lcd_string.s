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

  .org $8000


MESSAGE_POINTER = $02

message1: .asciiz "Shed-o-tron II "

message2: .asciiz "* * 22/8/22 * * "

irq_message: .asciiz "IRQ PRESSED"

reset:
  ldx #$ff
  txs
  
  lda #$92
  sta IER

  lda #$00
  sta PCR
  cli

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11000000 ; Set all pins on port A to input
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

  lda #<message1
  sta MESSAGE_POINTER
  lda #>message1
  sta MESSAGE_POINTER + 1


  jsr print


loop:
  lda #RED_LED
  sta PORTA
  jmp loop

print:
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  ldy #0
line1:
  lda (MESSAGE_POINTER),y
  beq print2
  jsr print_char
  iny
  jmp line1
  
print2:
  lda #%10101001
  jsr lcd_instruction
  ldy #0
  lda #<message2
  sta MESSAGE_POINTER
  lda #>message2
  sta MESSAGE_POINTER + 1
line2:
  lda (MESSAGE_POINTER),y
  beq end_print
  jsr print_char
  iny
  jmp line2

end_print:
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


new_message:
  lda #<irq_message
  sta MESSAGE_POINTER
  lda #>irq_message
  sta MESSAGE_POINTER + 1
  rts   


nmi:

irq:


  pha
  txa
  pha
  tya
  pha


  lda #$00
  sta PORTA
  lda #GREEN_LED
  sta PORTA

  jsr new_message
  jsr print

exit_irq:

; de-bounce delay before resetting interrupt
  ldy #$55 ; tweak the count-down to optimise debounce
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
