

  .code

; LCD Command masks
;E  = %01000000
;RW = %00100000
;RS = %00010000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;                              LCD Functions 
;;
;;
;;

lcd_2_start:
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_2_instruction
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_2_instruction
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_2_instruction
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_2_instruction
  jsr lcd_2_entry_mode
  jsr lcd_2_cursor_off
  jsr lcd_2_clear
  ;jsr lcd_add0
  rts

lcd_2_entry_mode:
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_2_instruction
  rts

lcd_2_home:
  lda #%00000010 ; cursor HOME
  jsr lcd_2_instruction
  rts

lcd_2_add0:
  lda #%10000000 ; back to zero position
  jsr lcd_2_instruction
  rts

lcd_2_clear:
  lda #%00000001 ; Clear display
  jsr lcd_2_instruction
  rts

lcd_2_cursor_off:
  lda #%00001100 ; Display on; cursor off; blink off
  jsr lcd_2_instruction
  rts

lcd_2_cursor_on:
  lda #%00001111 ; Display on; cursor on; blink on
  jsr lcd_2_instruction
  rts

lcd_2_line_1:
  lda #($80)
  jsr lcd_2_instruction
  rts

lcd_2_line_2:
  lda #($80 + $40)
  jsr lcd_2_instruction
  rts

;lcd_line_3:
;  lda #($80 + $14)
;  jsr lcd_instruction
;  rts

;lcd_line_4:
;  lda #($80 + $54)
;  jsr lcd_instruction
;  rts
 
lcd_2_wait:
  pha
  lda #%01110000  ; LCD data is input (don't change MSB BIT7, it has to stay ZERO for SHIFT Button input)
  sta DDRA_3

lcdbusy2:
  lda #RW
  sta PORTA_3
  lda #(RW | E)
  sta PORTA_3
  lda PORTA_3     ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #RW
  sta PORTA_3
  lda #(RW | E)
  sta PORTA_3
  lda PORTA_3       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcdbusy2

  lda #RW
  sta PORTA_3
  lda #%01111111  ; LCD data is output (don't change MSB BIT7, it has to stay ZERO for SHIFT Buttion input)
  sta DDRA_3
  pla
  rts

lcd_2_init:
  lda #%00000010 ; Set 4-bit mode : DO ONCE AT POWER UP
  sta PORTA_3
  ora #E
  sta PORTA_3
  and #%00001111
  sta PORTA_3
  rts

lcd_2_instruction:
  jsr lcd_2_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta PORTA_3
  ora #E         ; Set E bit to send instruction
  sta PORTA_3
  eor #E         ; Clear E bit
  sta PORTA_3
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTA_3
  ora #E         ; Set E bit to send instruction
  sta PORTA_3
  eor #E         ; Clear E bit
  sta PORTA_3
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   
;;        PRINT Characters on LCD - an ASCII value in Accumulator 
;;        is printed on the display
;;

print_2_char:
  jsr lcd_2_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #RS         ; Set RS
  sta PORTA_3
  ora #E          ; Set E bit to send instruction
  sta PORTA_3
  eor #E          ; Clear E bit
  sta PORTA_3
  pla
  and #%00001111  ; Send low 4 bits
  ora #RS         ; Set RS
  sta PORTA_3
  ora #E          ; Set E bit to send instruction
  sta PORTA_3
  eor #E          ; Clear E bit
  sta PORTA_3
  rts

