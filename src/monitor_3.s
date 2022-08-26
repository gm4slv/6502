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

  .org $8000

BASE_ADDRESS = $0000

DUMP_POINTER = $00

MESSAGE_POINTER = $04

INKEY = $02

LO_LO_ASCII = $06 ; 4 byte rolling store of entered key-press characters in ASCII
LO_HI_ASCII = $07
HI_LO_ASCII = $08
HI_HI_ASCII = $09

LO_BYTE = $0A         ; binary representation of entered key-presses
HI_BYTE = LO_BYTE + 1 ;  

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

  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1

  lda #<BASE_ADDRESS
  sta DUMP_POINTER
  lda #>BASE_ADDRESS
  sta DUMP_POINTER + 1

  jsr new_address


; main loop
loop:
  jsr scan      ; sets PORTA "row" pins to HIGH to allow for Interrupt detection via diode OR on "column" pins -> CB1
  jmp loop


;;;;;;;;;;;;; FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;

; update screen when new memory location is selected
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

print_data:

  lda (DUMP_POINTER),y
  jsr bintohex
  lda #" "
  jsr print_char
  lda (DUMP_POINTER),y
  jsr print_char

message_end:
  jsr print   ; add second line (cursor) after re-writing the top line
  rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; display 8 bytes of data for a "block" of memory
block_address:
  
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  ldy #$00
  ldx #$00

print_block_address:
  lda #"$"
  jsr print_char
  lda DUMP_POINTER + 1
  jsr bintohex
  lda DUMP_POINTER
  jsr bintohex

  lda #%10101001
  jsr lcd_instruction

print_block:

  lda (DUMP_POINTER),y
  jsr bintohex
  lda (DUMP_POINTER),y
  iny
  cpy #$08
  bne print_block


block_message_end:
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; re-draw line 2 cursor
print:
  
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


scan:             ; set ROW keypad outputs high as a source for triggering interrupt when a key is pressed
  ldy #%11110000
  sty PORTA
  rts


; convert a binary value 00000000 -> 00001111 ($00 to $0F) to its ASCII character using a simple lookup table
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
  lda #%01110000  ; LCD data is input (don't change MSB BIT7, it has to stay ZERO for SHIFT Button input)
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
  lda #%01111111  ; LCD data is output (don't change MSB BIT7, it has to stay ZERO for SHIFT Buttion input)
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


keypad_array: .byte "?DCBAF9630852E741"

get_key:

readKeypad:
  ldx #$04        ; Row 4 - counting down
  ldy #%10000000  ;
ScanRow:
  sty PORTA
  lda PORTA
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
  sta LO_BYTE
  lda DUMP_POINTER + 1
  sbc #$00
  sta DUMP_POINTER + 1
  sta HI_BYTE
dec_ok:
  rts


increment_address:

  clc
  lda DUMP_POINTER
  adc #$01
  sta DUMP_POINTER
  sta LO_BYTE
  bcc inc_ok
  inc DUMP_POINTER + 1
  lda DUMP_POINTER + 1
  sta HI_BYTE
inc_ok:
  rts


ascii_byte:   ; take four ascii characters representing HEX digits and convert tp TWO 8-bit binary bytes $00-$FF
  
  lda LO_HI_ASCII

  jsr ascii_bin
  clc
  asl
  asl
  asl
  asl
  sta LO_BYTE

  lda LO_LO_ASCII
  
  jsr ascii_bin
  ora LO_BYTE
  sta LO_BYTE

  lda HI_HI_ASCII
  jsr ascii_bin
  clc
  asl
  asl
  asl
  asl
  sta HI_BYTE

  lda HI_LO_ASCII
  
  jsr ascii_bin
  ora HI_BYTE
  sta HI_BYTE
  rts
  
ascii_bin:
  clc  
  cmp #$41
  bmi ascii_bin_num

ascii_bin_letter:
  clc 
  sec
  sbc #$37
  jmp end_ascii_bin

ascii_bin_num:
  and #%00001111

end_ascii_bin:
  rts 

  

nmi:

; interrupt is triggered by HIGH edge on VIA CB1 pin
; PORTA low nibble (keypad columns) inputs are diode ORed to CB1

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
  ;bne print_new_char    ; not set = leave
  beq check_a ; done this way to get around the limit in size of branch jumps....
  jmp handle_new_char

; choose action of "SHIFTed" key-press
check_a:
  lda INKEY       
  cmp #"A"
  ; move up one memory address and display contents
  bne check_b     
  jsr increment_address
  jsr new_address
  jmp exit_irq

check_b:
  lda INKEY
  cmp #"B"
  ; move down one memory address and display contents
  bne check_c
  jsr decrement_address
  jsr new_address
  jmp exit_irq

check_c:
  lda INKEY
  cmp #"C"
  ; clear screen back to normal display
  bne check_d
  lda #%00000001
  jsr lcd_instruction
  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1
  jsr new_address
  jmp exit_irq

check_d:
  lda INKEY
  cmp #"D"
  ; move monitor to entered 4-digit memory address
  bne check_e
  lda LO_BYTE
  sta DUMP_POINTER
  lda HI_BYTE
  sta DUMP_POINTER + 1
  jsr new_address
  jsr print
  jmp exit_irq

check_e:
  lda INKEY
  cmp #"E"
  ; insert (POKE) byte of data in to current memory address, then increment to next address
  bne check_f
  lda LO_BYTE
  ldy #$00
  sta (DUMP_POINTER),y
  jsr increment_address
  jsr new_address
  jsr print
  jmp exit_irq

check_f:
  lda INKEY
  cmp #"F"
  ; show 8-byte wide block of memory
  bne check_1
  ldy #$00
  lda LO_BYTE
  sta DUMP_POINTER
  lda HI_BYTE
  sta DUMP_POINTER + 1
  jsr block_address
  ;jsr print
  jmp exit_irq

check_1:
  ; run USER code from $3000
  jmp $3000

handle_new_char:
  lda HI_LO_ASCII  ; shuffle 4 bytes of ASCII character data as each new
  sta HI_HI_ASCII  ; character is typed
  lda LO_HI_ASCII 
  sta HI_LO_ASCII
  lda LO_LO_ASCII
  sta LO_HI_ASCII
  lda INKEY       ; get the new ASCII keypress value and... 
  sta LO_LO_ASCII ; store in low_nibble temp store
  jsr print_char  ; and print it on LCD
  
  jsr ascii_byte  ; convert the rolling 4-byte ASCII character data into two binary bytes

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
