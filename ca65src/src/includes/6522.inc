

  .code
  
; VIA Port addresses
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

T1CL = $6004
T1CH = $6005

ACR = $600b
PCR = $600c
IFR_1 = $600d
IER = $600e


via_1_init:

  lda #%01000000
  sta ACR
  lda #$0E
  sta T1CL
  lda #$27
  sta T1CH
  
  lda #%11011010  ; T1, CA1 active
  sta IER
  
  lda #$01  ;  CA1 active high-transition 
  sta PCR
  
  lda #%01111111 ; Set all pins on port B to output except BIT 7 which is used for "SHIFT/INSTRUCTION"  button
  sta DDRB
  lda #%11110000 ; Set low-nibble pins on port A to input and high-nibble pins to output, for keypad
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

  rts

