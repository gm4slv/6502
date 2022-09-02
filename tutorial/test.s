

byte4: ds 4,$44
byte2: ds 2,$cc


  .org $8000

reset:
  lda #$ff
  sta byte4
  lda #$ea
  sta byte2

loop:
  jmp loop

nmi:
irq:


  .org $fffa
  .word nmi
  .word reset
  .word irq

