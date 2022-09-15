
  .code

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
  and #$0F  ; mask off keypad input - only low 4 (keypad column) bits are read
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    
;;       key = <INDEX> ; pressing a key returns a 4-bit number 
;;       calculated as (Column * 4 ) + Row, in the range
;;       1 - 16 which acts as an index to a lookup-table. 
;;       The lookup table returns a byte value equal to the key's
;;       numerical value 
;;       e.g. 
;;       button 1 returns byte $01 / 00000001
;;       button F returns byte $0f / 00001111
;;    ____________________________________________________
;;   |     1 = <16> | 2 = <12> |    3 = <8> | A(10) = <4> |
;;   |______________|__________|____________|_____________|
;;   |     4 = <15> | 5 = <11> |    6 = <7> | B(11) = <3> |
;;   |______________|__________|____________|_____________|
;;   |     7 = <14> | 8 = <10> |    9 = <6> | C(12) = <2> |
;;   |______________|__________|____________|_____________|
;;   | E(14) = <13> | 0 = <9>  | F(15)= <5> | D(13) = <1> |
;;   |______________|__________|____________|_____________|
;;
;;            Button  ..   D    C    B    A    F    9    6    3    0    8    5    2    E    7    4    1
;;            <INDEX> 0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15,  16     
keypad_array: .byte $00, $0D, $0C, $0B, $0A, $0F, $09, $06, $03, $00, $08, $05, $02, $0E, $07, $04, $01


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  set ROW keypad outputs high as a source for triggering interrupt when a key is pressed
;;
;;
scan:
  ldy #%11110000
  sty PORTA_1
  rts

