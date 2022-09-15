
.SEGMENT "DISPLAY"

;.code

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
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  jsr lcd_entry_mode
  jsr lcd_cursor_off
  ;jsr lcd_clear
  ; CONSIDER CHANGE
  jmp lcd_clear
  ;rts

lcd_entry_mode:
  lda #%00000110 ; Increment and shift cursor; don't shift display
  ;jsr lcd_instruction
  ; CONSIDER CHANGE
  jmp lcd_instruction
  ;rts

lcd_home:
  lda #%00000010 ; cursor HOME
  ; CONDSIDER CHANGE
  jmp lcd_instruction
  ;jsr lcd_instruction
  ;rts

lcd_add0:
  lda #%10000000 ; back to zero position
  ; CONSIDER CHANGE
  jmp lcd_instruction
  ;jsr lcd_instruction
  ;rts

lcd_clear:
  lda #%00000001 ; Clear display
  jmp lcd_instruction
  ;jsr lcd_instruction
  ;rts

lcd_cursor_off:
  lda #%00001100 ; Display on; cursor off; blink off
  jmp lcd_instruction
  ;jsr lcd_instruction
  ;rts

lcd_cursor_on:
  lda #%00001111 ; Display on; cursor on; blink on
  jmp lcd_instruction
  ;jsr lcd_instruction
  ;rts

lcd_line_1:
  lda #($80)
  jmp lcd_instruction
  ;jsr lcd_instruction
  ;rts

lcd_line_2:
  lda #($80 + $40)
  jmp lcd_instruction
  ;jsr lcd_instruction
  ;rts

lcd_line_3:
  lda #($80 + $14)
  jmp lcd_instruction
  ;jsr lcd_instruction
  ;rts

lcd_line_4:
  lda #($80 + $54)
  jmp lcd_instruction
  ;jsr lcd_instruction
  ;rts
 
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;                              LCD 2 Functions 
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
  jmp lcd_2_clear
  ;jsr lcd_2_clear
  ;rts

lcd_2_entry_mode:
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jmp lcd_2_instruction
  ;jsr lcd_2_instruction
  ;rts

lcd_2_home:
  lda #%00000010 ; cursor HOME
  jmp lcd_2_instruction
  ;jsr lcd_2_instruction
  ;rts

lcd_2_add0:
  lda #%10000000 ; back to zero position
  jmp lcd_2_instruction
  ;jsr lcd_2_instruction
  ;rts

lcd_2_clear:
  lda #%00000001 ; Clear display
  jmp lcd_2_instruction
  ;jsr lcd_2_instruction
  ;rts

lcd_2_cursor_off:
  lda #%00001100 ; Display on; cursor off; blink off
  jmp lcd_2_instruction
  ;jsr lcd_2_instruction
  ;rts

lcd_2_cursor_on:
  lda #%00001111 ; Display on; cursor on; blink on
  jmp lcd_2_instruction
  ;jsr lcd_2_instruction
  ;rts

lcd_2_line_1:
  lda #($80)
  jmp lcd_2_instruction
  ;jsr lcd_2_instruction
  ;rts

lcd_2_line_2:
  lda #($80 + $40)
  jmp lcd_2_instruction
  ;jsr lcd_2_instruction
  ;rts

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
;;        PRINT Characters on LCD 2 - an ASCII value in Accumulator 
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;            print on line 1 or line 2 of LCD 1 or 2
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



print1:
  jsr lcd_line_1
  ldy #0
  jmp line
print2:
  jsr lcd_line_2
  ldy #0
  jmp line
print3:
  jsr lcd_line_3
  ldy #0
  jmp line
print4:
  jsr lcd_line_4
  ldy #0
  jmp line

print2_2:
  jsr lcd_2_line_2
  ldy #0
  jmp line2

line:
  lda (MESSAGE_POINTER),y
  beq @exit
  jsr print_char
  iny
  jmp line
@exit:
  rts

line2:
  lda (MESSAGE_POINTER),y
  beq @exit
  jsr print_2_char
  iny
  jmp line2
@exit:
  rts


