

  .include "./includes/6522.inc"
  .include "./includes/lcd.inc"
  .include "./includes/getkey.inc"
  .include "./includes/functions.inc"
  .include "./includes/rtc.inc"


;.SEGMENT "ZEROPAGE"
;.zeropage

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      MEMORY ALLOCATIONS
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;DUMP_POINTER     = $00 ; 2
;FLAGS            = $02 ; 1
;TOGGLE_TIME      = $03 ; 1
;CLOCK_LAST       = $04 ; 1
;MESSAGE_POINTER  = $05 ; 2
;LED_LAST         = $07 ; 1

;TICKS            = $10 ; 4
;CENTISEC         = $14 ; 1
;HUNDRED_HRS      = $15 ; 1
;TEN_HRS          = $16 ; 1
;HRS              = $17 ; 1
;TEN_MINUTES      = $18 ; 1
;MINUTES          = $19 ; 1
;TEN_SECONDS      = $1A ; 1
;SECONDS          = $1B ; 1

;INKEY            = $0200 ; 1
;ASCII            = $0201 ; 4
;BYTE             = $0205 ; 2
;TENS             = $0207 ; 1
;HUNDREDS         = $0208 ; 1
;HEX              = $0209 ; 2
;HEXB             = $020B ; 2
;TEMP             = $020D ; 1
;TEMP2            = $020E ; 1


;; ZERO PAGE

DUMP_POINTER    = $00 ; 2
FLAGS           = $02 ; 1
TOGGLE_TIME     = $03 ; 1
CLOCK_LAST      = $04 ; 1
MESSAGE_POINTER = $05 ; 2
LED_LAST        = $07 ; 1

TICKS       = $10 ; 4
CENTISEC    = $14 ; 1
HUNDRED_HRS = $15 ; 1
TEN_HRS     = $16 ; 1
HRS         = $17 ; 1
TEN_MINUTES = $18 ; 1
MINUTES     = $19 ; 1
TEN_SECONDS = $1A ; 1
SECONDS     = $1B ; 1



;; LOW RAM $200 ->
;;
INKEY     = $0200 ; 1
ASCII     = $0201 ; 4
BYTE      = $0205 ; 2
TENS      = $0207 ; 1
HUNDREDS  = $0208 ; 1
HEX       = $0209 ; 2
HEXB      = $020B ; 2
TEMP      = $020D ; 1
TEMP2     = $020E ; 1


;.code

  .org $8000

reset:
  ldx #$ff
  txs

  cli      ; interrupts ON

  jsr via_1_init ; set-up VIA_1 for LCD/Keypad 
  jsr lcd_init ; set-up 4-bit mode 
  jsr lcd_start ; set-up various features of lcd 

init_variables:
  stz TICKS
  stz TICKS + 1
  stz TICKS + 2
  stz TICKS + 3
  stz DUMP_POINTER
  stz DUMP_POINTER + 1
  stz MESSAGE_POINTER
  stz MESSAGE_POINTER + 1
  stz TOGGLE_TIME
  stz CLOCK_LAST
  stz LED_LAST
  stz CENTISEC
  stz FLAGS
  stz SECONDS
  stz TEN_SECONDS
  stz MINUTES
  stz HRS
  stz TEN_HRS
  stz TEN_MINUTES
  stz HUNDRED_HRS
  stz TEMP
  stz TEMP2
  stz TENS  

  

; put a precautionary RTS at end of "user" RAM area @ $30ff
; the "GO" function (<SHIFT>5) performs a "jsr $3000" to run
; whatever code has been entered into RAM at $3000 and
; we put RTS at $30ff to ensure the code returns when <SHIFT>5 is pressed
; even if nothing (or garbage) has been entered

user_ram:
  lda #$60
  sta $30ff
  
  
; go straight to MONITOR at startup
  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1
  jsr new_address

; main loop
loop:
  wai
  jsr check_flags
  ;jsr toggle_led
  jmp loop


;;;;;;;;;;;;; FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;

check_flags:
  bbs0 FLAGS, update_block_address
  bbs5 FLAGS, clock_time
  ; check other flags... other actions....
  rts

update_block_address:
  sec
  lda TICKS
  sbc TOGGLE_TIME
  cmp #$32
  bcc exit_update_block
  jsr block_address
  lda TICKS
  sta TOGGLE_TIME
  
exit_update_block:
  rts


clock_time:

  sec
  lda TICKS
  sbc CLOCK_LAST
  cmp #$32
  bcc exit_clock
  
  jsr lcd_cursor_off
  
  jsr lcd_home
  
  lda HUNDRED_HRS
  jsr bintoascii
  lda TEN_HRS
  jsr bintoascii
  lda HRS
  jsr bintoascii
  lda #':'
  jsr print_char
  lda TEN_MINUTES
  jsr bintoascii
  lda MINUTES
  jsr bintoascii
  lda #':'
  jsr print_char
  lda TEN_SECONDS
  jsr bintoascii
  lda SECONDS
  jsr bintoascii
  lda TICKS
  sta CLOCK_LAST
exit_clock:
  rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      update screen when new memory location is selected
;;
;;
new_address:
  
  jsr lcd_clear
  
  jsr lcd_cursor_on


print_address:
  lda #'$'
  jsr print_char
  lda DUMP_POINTER + 1
  jsr bintohex
  lda DUMP_POINTER
  jsr bintohex

  lda #' '
  jsr print_char

print_data:

  ldy #$00

  lda (DUMP_POINTER),y
  jsr bintohex
  lda #' '
  jsr print_char
  lda (DUMP_POINTER),y
  jsr print_char

message_end:
  jsr print   ; add second line (cursor) after re-writing the top line
  rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; display 8 bytes of data for a "block" of memory
;;
;;
block_address:
  
  jsr lcd_clear

  ldy #$00

print_block_address:
  lda #'$'
  jsr print_char
  lda DUMP_POINTER + 1
  jsr bintohex
  lda DUMP_POINTER
  jsr bintohex

  jsr lcd_line_2
  
print_block:

  lda (DUMP_POINTER),y
  jsr bintohex
  ;lda (DUMP_POINTER),y
  iny
  cpy #$08
  bne print_block


block_message_end:
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; re-draw line 2 cursor
;;
;;
print:
  
  jsr lcd_line_2

  ldy #0
line1:
  lda (MESSAGE_POINTER),y
  beq end_print
  jsr print_char
  iny
  jmp line1

end_print:

  rts




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Monitor function - decrement the selected address 
;;
;;
decrement_address:

  sec
  lda DUMP_POINTER
  sbc #$01
  sta DUMP_POINTER
  sta BYTE
  lda DUMP_POINTER + 1
  sbc #$00
  sta DUMP_POINTER + 1
  sta BYTE + 1
dec_ok:
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Monitor function - increment the selected address 
;;
;;

increment_address:

  clc
  lda DUMP_POINTER
  adc #$01
  sta DUMP_POINTER
  sta BYTE
  ;bcc inc_ok
  lda DUMP_POINTER + 1
  adc #$00
  sta DUMP_POINTER + 1
  sta BYTE + 1
inc_ok:
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Monitor function - increment the selected block of  addresses by 8 
;;
;;

increment_block:
  clc
  lda DUMP_POINTER
  adc #$08
  sta DUMP_POINTER
  sta BYTE
  lda DUMP_POINTER + 1
  adc #$00
  sta DUMP_POINTER + 1
  sta BYTE + 1
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Monitor function - decrement the selected block of  addresses by 8 
;;
;;

decrement_block:

  sec
  lda DUMP_POINTER
  sbc #$08
  sta DUMP_POINTER
  sta BYTE
  lda DUMP_POINTER + 1
  sbc #$00
  sta DUMP_POINTER + 1
  sta BYTE + 1
  rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;          use last 4 entered ASCII characters from the keypad and convert 
;;          them to TWO 8-bit binary bytes in RAM
;;
;;
ascii_byte:

  lda ASCII + 1

  jsr ascii_bin
  clc
  asl
  asl
  asl
  asl
  sta BYTE

  lda ASCII
  
  jsr ascii_bin
  ora BYTE
  sta BYTE

  lda ASCII + 3
  jsr ascii_bin
  clc
  asl
  asl
  asl
  asl
  sta BYTE + 1

  lda ASCII + 2
  
  jsr ascii_bin
  ora BYTE + 1
  sta BYTE + 1
  rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    toggle the display/update of Clock on each appropriate keypress
;;
toggle_clock:
  
  bbs5 FLAGS, reset_bit5
  smb5 FLAGS
  jmp exit_toggle_clock

reset_bit5:

  rmb5 FLAGS

exit_toggle_clock:
  
  rts
  ;jmp debounce

toggle_led:
  sec
  lda TICKS
  sbc LED_LAST
  cmp #100
  bcc exit_led
  lda PORTB_1
  eor #%00100000
  sta PORTB_1
  lda TICKS
  sta LED_LAST
exit_led:
  rts  


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    toggle the automatic update view of the "8-byte memory block"
;;
toggle_block:
  
  bbs0 FLAGS, reset_bit0
  smb0 FLAGS
  jmp exit_toggle_block

reset_bit0:

  rmb0 FLAGS

exit_toggle_block:

  rts
  ;jmp debounce

;debounce:
;  ldx #$ff
;  ldy #$ff
;delay:
;  nop
;  dex
;  bne delay
;  dey
;  bne delay
;  rts  
  

;;;;;;;;;;;;;;;;;; INTERRUPT HANDLERS ;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      CB1 : reset & restart timer
;;

cb1_handler:
  stz HUNDRED_HRS
  stz TEN_HRS
  stz TEN_MINUTES
  stz TEN_SECONDS
  stz HRS
  stz MINUTES
  stz SECONDS

  ;smb5 FLAGS

  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;     CB2 : lap-time pause timer
;;

cb2_handler:
  jsr toggle_clock
  rts
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                    MONITOR / KEYPAD 
;;
;;

keypad_handler:

  jsr get_key     ; READs from PORTA which also re-sets VIA's Interrupt flag
  sta INKEY       ; put the ASCII value of input into RAM ( $00 ) 
  
  lda PORTB_1       ; check for SHIFT/INSTRUCTION button
  and #%10000000
  beq check_keypress ; done this way to get around the limit in size of branch jumps....
  jmp handle_new_char
  
check_keypress:
  lda INKEY       

; choose action of "SHIFTed" key-press
check_a:
  cmp #'A'
  ; move up one memory address and display contents
  bne check_b     
  jsr increment_address
  jsr new_address
  jmp exit_key_irq

check_b:
  cmp #'B'
  ; move down one memory address and display contents
  bne check_c
  jsr decrement_address
  jsr new_address
  jmp exit_key_irq

check_c:
  cmp #'C'
  ; return to MONITOR
  bne check_d
  rmb5 FLAGS
  jsr lcd_clear
  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1
  
  jsr new_address
  jmp exit_key_irq

check_d:
  cmp #'D'
  ; move monitor to entered 4-digit memory address
  bne check_e
  lda BYTE
  sta DUMP_POINTER
  lda BYTE + 1
  sta DUMP_POINTER + 1
  jsr new_address
  jsr print
  jmp exit_key_irq

check_e:
  cmp #'E'
  ; insert (POKE) byte of data in to current memory address, then increment to next address
  bne check_f
  lda BYTE
  ldy #$00
  sta (DUMP_POINTER),y
  jsr increment_address
  jsr new_address
  jsr print
  jmp exit_key_irq

check_f:
  cmp #'F'
  ; show 8-byte wide block of memory
  bne check_1
  ;ldy #$00
  lda BYTE
  sta DUMP_POINTER
  lda BYTE + 1
  sta DUMP_POINTER + 1
  jsr block_address
  jmp exit_key_irq

check_1:
  cmp #'1'
  ; show/auto-update clock
  bne check_3
  jsr lcd_clear
  lda #<emt
  sta MESSAGE_POINTER
  lda #>emt
  sta MESSAGE_POINTER + 1
  jsr print
  smb5 FLAGS
  
  ;jsr show_clock
  jmp exit_key_irq

check_3:
  cmp #'3'
  bne check_6
  ;ldy #$00
  jsr increment_block
  jsr block_address
  jmp exit_key_irq

check_6:
  cmp #'6'
  bne check_9
  ;ldy #$00
  jsr decrement_block
  jsr block_address
  jmp exit_key_irq

check_9:
  cmp #'9'
  bne check_4
  jsr toggle_block
  jmp exit_key_irq

check_4:
  cmp #'4'
  bne check_5
  lda BYTE
  sta HEXB
  lda BYTE + 1
  sta HEXB + 1
  jsr byte_to_hex
  jmp exit_key_irq

check_5:
  cmp #'5'
  bne exit_key_irq
  jsr $3000
  jmp exit_key_irq


handle_new_char:
  lda ASCII + 2
  sta ASCII + 3
  lda ASCII + 1
  sta ASCII + 2
  lda ASCII
  sta ASCII + 1
  lda INKEY       ; get the new ASCII keypress value and... 
  sta ASCII
  jsr print_char  ; and print it on LCD
  
  jsr ascii_byte  ; convert the rolling 4-byte ASCII character data into two binary bytes

exit_key_irq:


  jsr scan  ; re-enable keypad

  rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nmi:
  rti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    interrupt is triggered by HIGH edge on VIA CA1 pin
;;     PORTA low nibble (keypad columns) inputs are diode ORed to CA1
;;

irq:
; put registers on the stack while handling the IRQ
  pha
  phx
  phy

;  find responsible hardware

;  Is it VIA_1?

  lda IFR_1   ; if IFR_1 has Bit7 set (ie sign=NEGATIVE) then it IS the source of the interrupt
  bpl next_device ; if it's not set (ie sign=POSITIVE) then branch to test the next possible device

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; IFR Flags
;; B7  B6  B5  B4  B3  B2  B1  B0
;; IRQ TI1 TI2 CB1 CB2 SR CA1 CA2
;;
;; Interrupt source is found by sequentially shifting IFR bit left to put bit-of-interest into the CARRY place
;; and then branching based on whether CARRY is SET or not
;;
;; Only add tests for IRQ sources in use, and adjust the ASLs in each test as necessary
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_timer1:
  asl           ; shift IFR left twice puts the TI1 bit into CARRY....
  asl
  bcc test_cb1  ; carry clear = next test
  bit T1CL_1      ; carry not clear = handle the TIMER interrupt
  jsr rtc
  jmp exit_irq

test_cb1:
  asl
  asl
  bcc test_cb2
  bit PORTB_1
  jsr cb1_handler
  jmp exit_irq

test_cb2:
  asl
  bcc test_ca1
  bit PORTB_1
  jsr cb2_handler
  jmp exit_irq

test_ca1:
  asl           ; shift CA1 bit into the CARRY bit & test
  asl
  bcc exit_irq        ; carry clear = leave
  jsr keypad_handler  ; carry not clear = handle the CA1 interrupt (keypad)
  jmp exit_irq


next_device:

exit_irq:
  ply
  plx
  pla


  rti

emt: .asciiz "hhh mm ss  MET"
splash: .asciiz "Mon>"
error_message: .asciiz "Error"

; Reset/IRQ vectors

;.segment "VECTORS"
  
  .org $FFFA

  .word nmi
  .word reset
  .word irq
