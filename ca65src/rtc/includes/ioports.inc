
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

SPI_PORT  = PORTB_3

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

;;;;;;;;;;;;;;;;;;;;
;; TIMER T1 used as TICK source for RTC - set for 10ms per tick
;; $270E = 9998d = count 10,000 phi2 cycles @ 1MHz = 10ms per interrupt
;;
;;  ACR : AUXILLAIRY CONTROL REGISTER
;;
;; |  7   |  6   |  5   |  4   |  3   |  2   |  1    |  0    |
;; |_____________|______|____________________|_______|_______|_
;; |   T1 Timer  |  T2  | Shift Reg Control  |  PB   |  PA   |
;; |  0      1   |  0   |  0      0      0   |  0    |  0    |
;;    
;;  T1 : Bit 7 = Squarewave on PB7, Bit 6 = Continuous Interrupts
;;  Bit 6 is set to allow repeating interrupts every 10ms
;;  Bit 7 is not set - we don't need Port B bit 7 square waves.

  lda #%01000000
  sta ACR_1
  lda #$0E
  sta T1CL_1
  lda #$27
  sta T1CH_1
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;
  ;;  IER - INTERRUPT ENABLE REGISTER
  ;;
  ;; |      7     |  6   |  5   |  4   |  3   |  2   |  1    |  0    |
  ;;_|____________|______|______|______|______|______|_______|_______|_
  ;; | Set/Clear  |  T1  |  T2  |  CB1 |  CB2 |  SR  |  CA1  |  CA2  |
  ;; |     1      |  1   |  0   |  1   |  1   |  0   |  1    |  0    |
  
  ;;
  ;; CA1 = Keypad interrupt
  
  lda #%11011010  ; | Set | T1 | CB1 | CB2 | CA1 | interrupts triggered
  sta IER_1
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;
  ;;  PCR - Peripheral Control Register
  ;;
  ;; |   7   |   6   |  5   |  4   |  3   |  2   |  1    |   0    |
  ;; |______________________|______|_____________________|________|
  ;; |     CB2 Control      | CB1  |     CA2 Control     |  CA1   |
  ;;
  ;;  CB2 : 010 = Input Positive edge (Test Button 2)
  ;;  CB1 : 1   = Positive edge (Test Button 1)
  ;;  CA2 : 000 = Input Negative edge (unused)
  ;;  CA1 : 1   = Positive edge (keypad)
  
  lda #%01010001  ;  
  sta PCR_1
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;
  
  lda #%01111111 ; Set all pins on port B to output  (LCD #1 ) except BIT 7 which is used for "SHIFT/INSTRUCTION"  button
  sta DDRB_1
  
  lda #%11110000 ; Set low-nibble pins on port A to input and high-nibble pins to output, for keypad
  sta DDRA_1

  rts

via_2_init:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; TIMER T1 is set up in functions.inc to act as source of beep tones
;;
;; INFORMATION ONLY: NO ACR CONFIG DONE HERE
;;
;;  ACR : AUXILLAIRY CONTROL REGISTER
;;
;; |  7   |  6   |  5   |  4   |  3   |  2   |  1    |  0    |
;; |_____________|______|____________________|_______|_______|
;; |   T1 Timer  |  T2  | Shift Reg Control  |  PB   |  PA   |
;;    
;;  T1 : Bit 7 = Squarewave on PB7, Bit 6 = Continuous Interrupts
;;  Bit 6 is set to allow repeating interrupts every 10ms
;;  Bit 7 is set and reset as needed to send beeps from Port B bit 7 square waves
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  lda #%10000111 ; Bits 0,1,2 = Output for SPI, Bit 6 = Input for SPI, Bit 7 = Beep out - T1 squarewave 
  sta DDRB_2
  
  lda #%11111111 ; All Bits = Output
  sta DDRA_2
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;
  ;;  IER - INTERRUPT ENABLE REGISTER
  ;;
  ;; |      7     |  6   |  5   |  4   |  3   |  2   |  1    |  0    |
  ;;_|____________|______|______|______|______|______|_______|_______|_
  ;; | Set/Clear  |  T1  |  T2  |  CB1 |  CB2 |  SR  |  CA1  |  CA2  |
  ;; |     1      |  1   |  0   |  1   |  1   |  0   |  1    |  0    |
  
  ;;
  ;; CA1 = Keypad interrupt
  
  lda #%10011000  ; | Set | CB1 | CB2 | interrupts triggered
  sta IER_2
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;
  ;;  PCR - Peripheral Control Register
  ;;
  ;; |   7   |   6   |  5   |  4   |  3   |  2   |  1    |   0    |
  ;; |______________________|______|_____________________|________|
  ;; |     CB2 Control      | CB1  |     CA2 Control     |  CA1   |
  ;;
  ;;  CB2 : 010 = Input Positive edge (Test Button 2)
  ;;  CB1 : 1   = Positive edge (Test Button 1)
  ;;  CA2 : 000 = Input Negative edge (unused)
  ;;  CA1 : 1   = Positive edge (keypad)
  
  lda #%01010001  ;  
  sta PCR_2
  
  rts

via_3_init:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TIMER MOVED BACK TO VIA_1
;;;; 24/9/22
  ;lda #%00000000 ; DON'T use PB7 as a T1 pulse timer clock output (ACR b7 = 0)
                 ; DON'T use T1 Timer in continuous reset-interrupt mode (ACR b6 = 1)
  ;sta ACR_3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;
  ;;  IER - INTERRUPT ENABLE REGISTER
  ;;
  ;; |      7     |  6   |  5   |  4   |  3   |  2   |  1    |  0    |
  ;;_|____________|______|______|______|______|______|_______|_______|_
  ;; | Set/Clear  |  T1  |  T2  |  CB1 |  CB2 |  SR  |  CA1  |  CA2  |
  ;; |     1      |  1   |  0   |  1   |  1   |  0   |  1    |  0    |
  
  ;;
  ;; CA1 = Keypad interrupt
  
  lda #%10011000  ; | Set | CB1 | CB2 | interrupts triggered
  sta IER_3
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;
  ;;  PCR - Peripheral Control Register
  ;;
  ;; |   7   |   6   |  5   |  4   |  3   |  2   |  1    |   0    |
  ;; |______________________|______|_____________________|________|
  ;; |     CB2 Control      | CB1  |     CA2 Control     |  CA1   |
  ;;
  ;;  CB2 : 010 = Input Positive edge (Test Button 2)
  ;;  CB1 : 1   = Positive edge (Test Button 1)
  ;;  CA2 : 000 = Input Negative edge (unused)
  ;;  CA1 : 1   = Positive edge (keypad)
  
  lda #%01010001  ;  
  sta PCR_3
  
  
  lda #%11111111 ; set all pins on port A to output for now 
  sta DDRA_3
  lda #%10000111 ; Bits 0,1,2 = Output for SPI, Bit 6 = Input for SPI, Bit 7 = Beep out - T1 squarewave 
  sta DDRB_3
  
  
  rts



