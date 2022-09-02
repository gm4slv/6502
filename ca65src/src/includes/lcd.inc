

  .code

; LCD Command masks
E  = %01000000
RW = %00100000
RS = %00010000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;                              LCD Functions 
;;
;;
;;

lcd_start:
  ;lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  ;jsr lcd_instruction
  jsr lcd_entry_mode
  jsr lcd_cursor_off
  jsr lcd_clear
  rts

lcd_entry_mode:
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  rts

lcd_home:
  lda #%00000010 ; cursor HOME
  jsr lcd_instruction
  rts
  
lcd_clear:
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  rts

lcd_cursor_off:
  lda #%00001100 ; Display on; cursor off; blink off
  jsr lcd_instruction
  rts

lcd_cursor_on:
  lda #%00001111 ; Display on; cursor on; blink on
  jsr lcd_instruction
  rts

lcd_line_2:
  lda #%10101001
  jsr lcd_instruction
  rts
  
lcd_wait:
  pha
  lda #%01110000  ; LCD data is input (don't change MSB BIT7, it has to stay ZERO for SHIFT Button input)
  sta DDRB_1
lcdbusy:
  lda #RW
  sta PORTB_1
  lda #(RW | E)
  sta PORTB_1
  lda PORTB_1     ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #RW
  sta PORTB_1
  lda #(RW | E)
  sta PORTB_1
  lda PORTB_1       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcdbusy

  lda #RW
  sta PORTB_1
  lda #%01111111  ; LCD data is output (don't change MSB BIT7, it has to stay ZERO for SHIFT Buttion input)
  sta DDRB_1
  pla
  rts

lcd_init:
  lda #%00000010 ; Set 4-bit mode : DO ONCE AT POWER UP
  sta PORTB_1
  ora #E
  sta PORTB_1
  and #%00001111
  sta PORTB_1
  rts

lcd_instruction:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta PORTB_1
  ora #E         ; Set E bit to send instruction
  sta PORTB_1
  eor #E         ; Clear E bit
  sta PORTB_1
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTB_1
  ora #E         ; Set E bit to send instruction
  sta PORTB_1
  eor #E         ; Clear E bit
  sta PORTB_1
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   
;;        PRINT Characters on LCD - an ASCII value in Accumulator 
;;        is printed on the display
;;

print_char:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #RS         ; Set RS
  sta PORTB_1
  ora #E          ; Set E bit to send instruction
  sta PORTB_1
  eor #E          ; Clear E bit
  sta PORTB_1
  pla
  and #%00001111  ; Send low 4 bits
  ora #RS         ; Set RS
  sta PORTB_1
  ora #E          ; Set E bit to send instruction
  sta PORTB_1
  eor #E          ; Clear E bit
  sta PORTB_1
  rts

