
  .org $8000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;      READ THE 4x4 keypad using  VIA_1 PORTA 
;;
;;      Accumulator holds the ASCII value of the pressed key when it returns
;;

get_key:
readKeypad:
  ldx #$04        ; Row 4 - counting down
  ldy #%10000000  ;
ScanRow:
  sty PORTA_1
  lda PORTA_1
  and #%00001111  ; mask off keypad input - only low 4 (keypad column) bits are read
  cmp #$00
  bne Row_Found   ; non-zero means a row output has been connected via a switch to a column input
  dex             ; zero means it hasn't been found, so check next row down
  tya
  lsr
  tay
  cmp #%00001000
  bne ScanRow
  lda #$ff
  rts
Row_Found:
  stx TEMP ; store row
  ldy #$ff
FindCol:
  iny
  lsr
  bcc FindCol
  tya
  asl
  asl  ; col * 4
  clc
  adc TEMP ; add row 
  tax
  lda keypad_array,x
  rts


keypad_array: .byte "?DCBAF9630852E741"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  set ROW keypad outputs high as a source for triggering interrupt when a key is pressed
;;
;;
scan:
  lda #%11110000
  sta PORTA_1
  rts

