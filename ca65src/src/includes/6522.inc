

  .code
  
; VIA_1 Port addresses
PORTB_1   = $6000
PORTA_1   = $6001
DDRB_1    = $6002
DDRA_1    = $6003

T1CL_1    = $6004
T1CH_1    = $6005

ACR_1     = $600b
PCR_1     = $600c
IFR_1     = $600d
IER_1     = $600e


via_1_init:

  lda #%01000000
  sta ACR_1
  lda #$0E
  sta T1CL_1
  lda #$27
  sta T1CH_1
  
  lda #%11011010  ; T1, CA1 active
  sta IER_1
  
  lda #$01  ;  CA1 active high-transition 
  sta PCR_1
  
  lda #%01111111 ; Set all pins on port B to output except BIT 7 which is used for "SHIFT/INSTRUCTION"  button
  sta DDRB_1
  lda #%11110000 ; Set low-nibble pins on port A to input and high-nibble pins to output, for keypad
  sta DDRA_1

  rts

