

  .code

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
  jsr print_char
  rts

single_figure:
  asl
  tax
  inx
  lda binascii,x
  jsr print_char
  rts


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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Convert a decimal number entered at keypad into its
;;      HEX equivalent and display
;;

byte_to_hex:

  jsr lcd_clear
  lda HEXB + 1
  and #$0f
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  lda HEXB
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  lda #'d'
  jsr print_char
  lda #'='
  jsr print_char
  lda #'$'
  jsr print_char

  lda HEXB ; lo byte
  pha
  lsr
  lsr
  lsr
  lsr
  cmp #10
  bpl error
  jsr mult10
  sta TENS
  pla
  and #%00001111 ; UNITS
  cmp #10
  bpl print_error
;  jsr mult10
  clc
  adc TENS
  sta HEX

  lda HEXB + 1 ; hi byte
  and #%00001111
  cmp #10
  bpl print_error
  jsr mult10
  jsr mult10 ; hundreds
  adc HEX
  
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  jmp exit_byte_to_hex

error:
  pla
print_error:
  lda #<error_message
  sta MESSAGE_POINTER
  lda #>error_message
  sta MESSAGE_POINTER + 1
  jsr print
  ;jsr lcd_cursor_off
  rts

exit_byte_to_hex:
  jsr lcd_line_2
  
  rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  (A * 8) + (A * 2) = A * 10 

mult10:
  pha
  asl
  asl
  asl
  sta TEMP2 ; A*8
  pla
  asl      ; A*2
  adc TEMP2 ; A*10
  rts




