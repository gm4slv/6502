
  .code
  
; VIA_1 Port addresses
VIA_1     = $6000
PORTB_1   = VIA_1
PORTA_1   = VIA_1 + 1
DDRB_1    = VIA_1 + 2
DDRA_1    = VIA_1 + 3
T1CL_1    = VIA_1 + 4
T1CH_1    = VIA_1 + 5
T1LL_1    = VIA_1 + 6
T1LH_1    = VIA_1 + 7
T2CL_1    = VIA_1 + 8
T2CH_1    = VIA_1 + 9
SR_1      = VIA_1 + 10
ACR_1     = VIA_1 + 11
PCR_1     = VIA_1 + 12
IFR_1     = VIA_1 + 13
IER_1     = VIA_1 + 14
PORTA_NO_HS_1 = VIA_1 + 15

; VIA_2 Port addresses
VIA_2     = $5000
PORTB_2   = VIA_2
PORTA_2   = VIA_2 + 1
DDRB_2    = VIA_2 + 2
DDRA_2    = VIA_2 + 3
T1CL_2    = VIA_2 + 4
T1CH_2    = VIA_2 + 5
T1LL_2    = VIA_2 + 6
T1LH_2    = VIA_2 + 7
T2CL_2    = VIA_2 + 8
T2CH_2    = VIA_2 + 9
SR_2      = VIA_2 + 10
ACR_2     = VIA_2 + 11
PCR_2     = VIA_2 + 12
IFR_2     = VIA_2 + 13
IER_2     = VIA_2 + 14
PORTA_NO_HS_2 = VIA_2 + 15

; VIA_3 Port addresses
VIA_3     = $4800
PORTB_3   = VIA_3
PORTA_3   = VIA_3 + 1
DDRB_3    = VIA_3 + 2
DDRA_3    = VIA_3 + 3
T1CL_3    = VIA_3 + 4
T1CH_3    = VIA_3 + 5
T1LL_3    = VIA_3 + 6
T1LH_3    = VIA_3 + 7
T2CL_3    = VIA_3 + 8
T2CH_3    = VIA_3 + 9
SR_3      = VIA_3 + 10
ACR_3     = VIA_3 + 11
PCR_3     = VIA_3 + 12
IFR_3     = VIA_3 + 13
IER_3     = VIA_3 + 14
PORTA_NO_HS_3 = VIA_3 + 15

; ACIA_1 Port Addresses
ACIA_1    = $4400
S_TXRX_1  = ACIA_1      ; TXD / RXD
S_STA_1   = ACIA_1 + 1  ; Status
S_COM_1   = ACIA_1 + 2  ; Command
S_CON_1   = ACIA_1 + 3  ; Control


via_1_init:


  
  lda #%10011010  ; CB2, CA1 active
  sta IER_1
  
  lda #%01010001  ;  CA1 active high-transition, CB2 low
  sta PCR_1
  
  lda #%01111111 ; Set all pins on port B to output except BIT 7 which is used for "SHIFT/INSTRUCTION"  button
  sta DDRB_1
  lda #%11110000 ; Set low-nibble pins on port A to input and high-nibble pins to output, for keypad
  sta DDRA_1

  rts

via_2_init:

;; TIMER T1 is set up in functions.inc to act as source of beep tones

  lda #%11111111 ; set all pins on port A & B to output
  sta DDRA_2
  sta DDRB_2
  lda #%00000000
  sta IER_2
  rts

via_3_init:

;; TIMER T1 used as TICK source for RTC - set for 10ms per tick
;; $270E = 9998d = count 10,000 phi2 cycles @ 1MHz = 10ms per interrupt

  lda #%01000000 ; DON'T use PB7 as a T1 pulse timer clock output (ACR b7 = 0)
                 ; Use T1 Timer in continuous reset-interrupt mode (ACR b6 = 1)
  sta ACR_3
  
  ; set T1 delay for 10ms interrupts
  lda #$0E
  sta T1CL_3
  lda #$27
  sta T1CH_3
  
  lda #%11000000  ; Interrupt / T1 interrupt active
  sta IER_3

  lda #%11111111 ; set all pins on port A & B to output for now 
  sta DDRA_3
  sta DDRB_3
  
  rts



