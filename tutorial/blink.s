

  .org $8000

reset:
  lda #$00
  sta PORTA
  sta PORTA + 1
  
  jmp test

loop:

  jmp loop

  ldy $00

test:
  lda (PORTA),y
  iny
  cmp #$FF
  beq loop


PORTA: ds 2

  .org $fffc
  .word reset
  .word $0000
