;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;     Ben Eater's "Binary to decimal number" routine
;;
;;     https://www.youtube.com/watch?v=v3-a-zqKfgA
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; We need caller to set VALUE and VALUE + 1 with the low and high bytes of the number to 
;; be printed. 

;; When we return we leave the number converted to an ascii string that can be printed 

print_value:
  
  stz num_message
  
  
   ; clear the string to hold the result

  
divide:

; initialize remainder to  be zero
  stz MOD10
  stz MOD10 + 1

  clc
  ldx #16    ; index for looping through the 16 bits of VALUE and VALUE+1
  
div_loop:

; rotate QUOTIENT and REMAINDER
; this effectively moved the point that we're subtracting
; 10 (to divide-by-ten) bit-by-bit through the VALUE
; checking ast each bit-place if we find a point where the subtraction of 10
; leaves a positive remainder

  rol VALUE       ; rotate each bit of VALUE into MOD10 in turn
  rol VALUE + 1
  rol MOD10
  rol MOD10 + 1

; a, y = DIVIDEND minus DIVISOR
  sec            ; subtract 10d from MOD10 and test the remainder
  lda MOD10
  sbc #10
  tay           ; save low BYTE of the subtraction in Y
  lda MOD10 + 1 ; load the high BYTE into A
  sbc #0        ; finish the 16-bit two step "subtract 10" and leave the HIGH byte result in A
  
  bcc ignore_result ; REMAINDER is negative, we borrowed from CARRY, therefore DIVIDEND was LESS THAN the DIVISOR so we
                    ; skip past the next 2 instructions, we need to find a situation where the REMAINDER was POSITIVE
                    ; i.e. CARRY was left alone
                    


; DIVIDEND was > DIVISOR, REMAINDER is POSITIVE so we put the REMAINDER (held in y and a) back to
; MOD10 and MOD10 + 1
 
  sty MOD10         
  sta MOD10 + 1    

; we now go around again...

ignore_result:

  dex          ; we need to process the next bit of VALUE using the new MOD10/MOD10+1
  bne div_loop ; until all 16 bits have been processed

; MOD10 now finally holds the required binary number of the (n'th) decimal digit of VALUE


; need to rotate the VALUE to put carry back at the beginning and set it up for the next digit calculation
  rol VALUE     ; 
  rol VALUE + 1 ;  VALUE/VALUE + 1 now holds previous VALUE divided by 10, ignoring the remainder ready for the 
                ;  next digit calculation
                 
  lda MOD10     ;  put calculated (n'th) digit into A to send to the ouptut string
  
  clc
  adc #$30     ; add $30 to convert the number into its ASCII encoded version
  
  jsr push_char ; send the new digit to be added to the output num_message string, in the
                ; correct place (at the far end)
 
; check if VALUE/VALUE + 1 is ZERO (we've done all the decimal digits of the initial VALUE/VALUE+1)
; If not, go back round and check the next digit

  lda VALUE
  ora VALUE + 1 
  bne divide

;; our result is that "num_message" now holds an ASCII string, 
;; zero terminated, representing the input 16 bit VALUE
;;
;; we don't print it from here. 
;;
;; to print it we use the normal method
;;
;; lda #<num_message
;; sta MESSAGE_POINTER
;; lda #>num_message
;; sta MESSAGE_POINTER + 1
;; jsr 'print' (i.e. whichever print function we need to put the number on the correct LCD line)

  
  rts


  

;  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  
;; put each digit onto the num_message string at the end - the string is shuffled
;; each time to build it "backwards"


push_char:
  pha
  ldy #0
char_loop:
  lda num_message,y
  tax
  pla
  sta num_message,y
  iny
  txa
  pha
  bne char_loop
  pla
  sta num_message,y
  rts
