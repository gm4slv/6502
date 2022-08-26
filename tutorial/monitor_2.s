; VIA Port addresses
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

PCR = $600c
IFR = $600d
IER = $600e

; LCD Command masks
E  = %01000000
RW = %00100000
RS = %00010000

SHIFT = %10000000

  .org $8000

BASE_ADDRESS = $3000

DUMP_POINTER = $00

MESSAGE_POINTER = $04

INKEY = $02


splash: .asciiz "mon:$ "

reset:
  ldx #$ff
  txs
  
  lda #$92  ; IRQ set CB1 enabled
  sta IER

  lda #$10  ; CB1 active high-transition 
  sta PCR

  cli      ; interrupts ON

  lda #%01111111 ; Set all pins on port B to output except BIT 7 which is used for "SHIFT/INSTRUCTION"  button
  sta DDRB
  lda #%11110000 ; Set low-nibble pins on port A to input and high-nibble pins to output, for keypad
  sta DDRA

  jsr lcd_init
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction
 
  ldy #$00
  lda #$00
fill_ram:
  sta BASE_ADDRESS,y
  iny
  cpy #$0f
  bne fill_ram

  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1


  ;jsr print

  lda #<BASE_ADDRESS
  sta DUMP_POINTER
  lda #>BASE_ADDRESS
  sta DUMP_POINTER + 1

  jsr new_address

loop:
  jsr scan      ; sets PORTA "row" pins to HIGH to allow for Interrupt detection via diode OR on "column" pins -> CB1
  jmp loop

new_address:
  

  lda #%00000001 ; Clear display
  jsr lcd_instruction

  ldy #$00
  ldx #$00

print_address:
  lda #"$"
  jsr print_char
  lda DUMP_POINTER + 1
  jsr bintohex
  lda DUMP_POINTER
  jsr bintohex

  lda #" "
  jsr print_char


;new_line:
;  lda #%10101001
;  jsr lcd_instruction

print_data:

  lda (DUMP_POINTER),y
  jsr bintohex
  lda #" "
  jsr print_char
  lda (DUMP_POINTER),y
  jsr print_char
  ;iny
  ;cpy #$08
  ;bne line2


message_end:
  jsr print   ; add second line splash
  rts


print:
  ;lda #%00000001 ; Clear display
  ;jsr lcd_instruction
new_line:
  lda #%10101001
  jsr lcd_instruction

  ldy #0
line1:
  lda (MESSAGE_POINTER),y
  beq end_print
  jsr print_char
  iny
  jmp line1

end_print:

  rts




scan:
  ldy #%11110000
  sty PORTA
  rts


bintohex:
  pha
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexascii,x
  jsr print_char
  pla
  and #$0f
  tax
  lda hexascii,x
  jsr print_char
  rts

hexascii: .byte "0123456789ABCDEF"


lcd_wait:
  pha
  lda #%01110000  ; LCD data is input (don't flip BIT7, it has to stay ZERO for SHIFT Button input)
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #RW
  sta PORTB
  lda #(RW | E)
  sta PORTB
  lda PORTB       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcdbusy

  lda #RW
  sta PORTB
  lda #%01111111  ; LCD data is output (don't flip BIT7, it has to stay ZERO for SHIFT Buttion input)
  sta DDRB
  pla
  rts

lcd_init:
  lda #%00000010 ; Set 4-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB
  rts

lcd_instruction:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTB
  ora #E         ; Set E bit to send instruction
  sta PORTB
  eor #E         ; Clear E bit
  sta PORTB
  rts

print_char:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  pla
  and #%00001111  ; Send low 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  rts

; interrupt is triggered by HIGH edge on VIA CB1 pin
; PORTA low nibble (keypad columns) inputs are diode ORed to CB1
; extend as needed.....

keypad_array: .byte "?DCBAF9630852E741"

get_key:

readKeypad:
  ldx #$04 ; Row 4 - counting down
  ldy #%10000000 ; Row 1
ScanRow:
  sty PORTA
  lda PORTA
  and #%00001111 ; mask off keypad only
  cmp #$00
  bne Row_Found
  dex ; count row down
  tya
  lsr
  tay
  cmp #%00001000
  bne ScanRow
  lda #$ff
  rts
Row_Found:
  stx $405 ; store row
  ldy #$ff
FindCol:
  iny 
  lsr
  bcc FindCol
  tya
  asl 
  asl  ; col * 4
  clc
  adc $405 ; add row 
  tax
  lda keypad_array,x
  rts


decrement_address:

  sec
  lda DUMP_POINTER
  sbc #$01
  sta DUMP_POINTER
  lda DUMP_POINTER + 1
  sbc #$00
  sta DUMP_POINTER + 1
dec_ok:
  rts


increment_address:

  clc
  lda DUMP_POINTER
  adc #$01
  sta DUMP_POINTER
  bcc inc_ok
  inc DUMP_POINTER + 1
inc_ok:
  rts

nmi:

irq:
; put registers on the stack while handling the IRQ
  pha
  txa
  pha
  tya
  pha


  ; do interrupt-driven things
  jsr get_key
  sta INKEY       ; put the ASCII value of input into RAM ( $00 ) 
  ;jsr print_char
  lda PORTB       ; check for SHIFT/INSTRUCTION button
  and #%10000000
  bne print_new_char    ; not set = leave

check_a:
  lda INKEY       ; set = check last keypress
  cmp #"A"        ; "A" with "Shift"?
  bne check_b     ; no? = check for B
  ;lda #<message_a
  ;sta MESSAGE_POINTER
  ;lda #>message_a
  ;sta MESSAGE_POINTER + 1
  ;jsr print
  jsr increment_address
  jsr new_address
  jmp exit_irq

check_b:
  lda INKEY
  cmp #"B"
  bne check_c
  ;lda #<message_b
  ;sta MESSAGE_POINTER
  ;lda #>message_b
  ;sta MESSAGE_POINTER + 1
  ;jsr print
  jsr decrement_address
  jsr new_address
  jmp exit_irq

check_c:
  lda INKEY
  cmp #"C"
  bne check_d
  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1
  jsr print
  jmp exit_irq

check_d:
  lda INKEY
  cmp #"D"
  bne check_e
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  jsr print
  jmp exit_irq



check_e:
  jmp exit_irq

check_f:
  jmp exit_irq


print_new_char:
  lda INKEY
  jsr print_char


exit_irq:
  
  
; de-bounce delay before resetting interrupt
  ldy #$FF ; tweak the count-down to optimise debounce
  ldx #$ff ;
delay:
  dex
  bne delay
  dey
  bne delay

  bit PORTB     ; clear VIA interrupt by reading from PORTB - using the interrupt source CB1 (should move to CA1 on PORTA!)

  ;lda #$00
  ;sta PORTA

; restore registers
  pla
  tay
  pla
  tax
  pla

  rti


; Reset/IRQ vectors
  .org $fffa
  .word nmi
  .word reset
  .word irq
