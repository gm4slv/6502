

  .code




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;        Use T1 Timer in free-run mode to put pulse
;;        train on PB7 at rate determined by
;;        the chosen delay. Tone output is enabled by
;;        setting bit7 of ACR register and disabled by
;;        resetting it. This should really be done by or'ing 
;;        %10000000 with the current value of ACR, to preserve
;;        the other bit-values. At the moment it's just a two 
;;        state setting: 11000000 = Tone On, 01000000 = Tone off.
;;        bit6 of ACR sets T1 in free-run repeat mode and stays set
;;

;; T1 Timer values:

;; (Phi2 / (2 * f) ) - 2
;;
;;  Phi2 = 1MHz = 1,000,000
;;
;;    f  = count => Hex    => Counter Low : Counter High
;; ========================================================= 
;;  50Hz = 9998d => $270E  => T1CL = $0E  : T1CH = $27 
;; 100Hz = 4998d => $1386  => T1CL = $86  : T1CH = $13
;; 200Hz = 2498d => $09C2  => T1CL = $C2  : T1CH = $09
;; 500Hz =  998d => $03E6  => T1CL = $E6  : T1CH = $03
;; 800Hz =  623d => $026F  => T1CL = $6F  : T1CH = $02 
;; 1kHz  =  498d => $01F2  => T1CL = $F2  : T1CH = $01
;; 2kHz  =  248d => $00F8  => T1CL = $F8  : T1CH = $00
;;
;; USING VIA_2 for the beep Timer/output
;;
;; DO NOT CONFIGURE T1 TIMER settings in ioports.inc
;; They are set here whenever the beep is needed
;;

count_50 = $270E
count_100 = $1386
count_200 = $09C2
count_500 = $03E6
count_800 = $026F
count_1k = $01F2
count_2k = $00F8

;;               50Hz, 100Hz, 200Hz, 500Hz, 800Hz, 1kHz, 2kHz
beepList: .word $270E, $1386, $09C2, $03E6, $026F, $01F2, $00F8

;; Load A with the required index and call beep_from_list

beep_from_list:
  
  asl
  tay
  lda beepList,y
  sta T1CL_2
  iny
  lda beepList,y
  sta T1CH_2
  
  lda #%11000000
  sta ACR_2
  ;jsr beep_on 
  ; CONSIDER Change:
  ;
  ; jsr beep_on
  ; rts
  ;
  ; becomes
  ; 
  jmp beep_on
  ;rts
  
beep:

;; 800Hz keybeep

  lda #<count_800
  sta T1CL_2
  lda #>count_800
  sta T1CH_2
  ;jsr beep_on
  ; CONSIDER Change:
  ;
  ; jsr beep_on
  ; rts
  ;
  ; becomes
  ; 
  jmp beep_on
 
  ;rts
  
beep_on:
    lda TICKS
    sta BEEP_ON_TIME
    lda #%11000000
    sta ACR_2
    smb7 FLAGS
    rts
    
beep_off:
  rmb7 FLAGS
  lda #%01000000
  sta ACR_2
  lda #$0A              ; restore standard 0.1s Beep length in case the caller had set a
  sta BEEP_DELAY_TIME   ; new BEEP_DELAY_TIME
  
  rts

beep_from_pointer:  ; put the 2 bytes for the required count into BEEP_POINTER and BEEP_POINTER + 1 and then
                    ; call beep_from_pointer

  
  lda BEEP_POINTER 
  sta T1CL_2
  lda BEEP_POINTER + 1
  sta T1CH_2

  ;jsr beep_on
  ; CONSIDER Change:
  ;
  ; jsr beep_on
  ; rts
  ;
  ; becomes
  ; 
  jmp beep_on
  
  ;rts  

beep2: ; high/low beep for boot-up success notification

; 1kHz
  lda #<count_1k
  sta T1CL_2
  lda #>count_1k
  sta T1CH_2

  lda #%11000000
  sta ACR_2
  
  jsr beep_delay

; 800Hz
  lda #<count_800
  sta T1CL_2
  lda #>count_800
  sta T1CH_2

  lda #%01000000
  sta ACR_2
  rts  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      basic loop delay to make the beep  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

beep_delay:
  ldx #$ff
  ldy #$38  ; <= set here to adjust the beep length
@loop:
  nop
  dex
  bne @loop
  dey
  bne @loop
  rts




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;          convert an 8-bit binary number from Accumulator, in range 00000000 -> 11111111 ($00 to $FF)
;;          to its HEX number encode as ASCII -  using a simple lookup table. Store each digit in RAM. Accumulator
;;          holds the last/low digit on return.
;;


bintohex:
  pha
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexascii,x
  sta HI_DIGIT
  pla
  and #$0f
  tax
  lda hexascii,x
  sta LO_DIGIT
  rts

hexascii: .byte "0123456789ABCDEF"

bintohex_2:
  pha
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexascii,x
  jsr print_2_char
  pla
  and #$0f
  tax
  lda hexascii,x
  jsr print_2_char
  rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    convert a binary (hex) value in Accumulator into
;;    its ASCII equivalent character in decimal 0-99 and print it
;;    this converts hex/binary numbers from the RTC into human readable
;;    decimal for display on clock


bintoascii:

  cmp #10
  bmi single_figure
  asl
  tax
  lda binascii,x
  jsr print_char

  inx

  lda binascii,x
  ;jsr print_char
  ; CONSIDER CHANGE
  jmp print_char
  ;rts

single_figure:
  asl
  tax
  inx
  lda binascii,x
  ;jsr print_char
  ;CONSIDER CHANGE
  jmp print_char
  ;rts

bintoascii_2:

  cmp #10
  bmi single_figure_2
  asl
  tax
  lda binascii,x
  jsr print_2_char

  inx

  lda binascii,x
  ;jsr print_2_char
  ; CONSIDER CHANGE
  jmp print_2_char
  ;rts

single_figure_2:
  asl
  tax
  inx
  lda binascii,x
  ;jsr print_2_char
  ; CONSIDER CHANGE
  jmp print_2_char
  ;rts



  

binascii: .byte "00010203040506070809"
          .byte "10111213141516171819"
          .byte "20212223242526272829"
          .byte "30313233343536373839"
          .byte "40414243444546474849"
          .byte "50515253545556575859"
          .byte "60616263646566676869"
          .byte "70717273747576777879"
          .byte "80818283848586878889"
          .byte "90919293949596979899"



