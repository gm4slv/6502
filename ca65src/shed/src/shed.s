
.zeropage

DUMP_POINTER:     .res 2
FLAGS:            .res 1
TOGGLE_TIME:      .res 1
CLOCK_LAST:       .res 1
MESSAGE_POINTER:  .res 2
TICKS:            .res 4
CENTISEC:         .res 1
HUNDRED_HRS:      .res 1
TEN_HRS:          .res 1
HRS:              .res 1
TEN_MINUTES:      .res 1
MINUTES:          .res 1
TEN_SECONDS:      .res 1
SECONDS:          .res 1
MEM_POINTER:      .res 2

.bss

INKEY:            .res 1
KEY_PRESS:        .res 4
BYTE:             .res 2
TENS:             .res 1
HUNDREDS:         .res 1
HEX:              .res 2
HEXB:             .res 2
TEMP:             .res 1
TEMP2:            .res 1
HI_DIGIT:         .res 1
LO_DIGIT:         .res 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;        INCLUDES 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "../includes/ioports.inc"
.include "../includes/lcd.inc"
.include "../includes/getkey.inc"
.include "../includes/functions.inc"
.include "../includes/rtc.inc"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;         START HERE
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.code

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
  stz MEM_POINTER
  stz MEM_POINTER + 1
  stz HI_DIGIT
  stz LO_DIGIT

memory_test:

  lda #<mem_start_msg
  sta MESSAGE_POINTER
  lda #>mem_start_msg
  sta MESSAGE_POINTER + 1
  jsr print1
  
;; test then clear RAM between 
;; $0200 - $3FFF - avoids the ZP and STACK areas

  lda #$02            ; start at $0200
  sta MEM_POINTER + 1
  ldy #$00
loop_ram:
  lda #$AA              ; test with 10101010
  sta (MEM_POINTER),y   ; write test value to RAM
  lda #$FF              ; remove test value from A
  lda (MEM_POINTER),y   ; read RAM contents into A
  cmp #$AA              ; compare to expected value
  bne mem_fail_1
  lda #$55              ; repeat test with 01010101
  sta (MEM_POINTER),y
  lda #$FF
  lda (MEM_POINTER),y
  cmp #$55
  bne mem_fail_2
  lda #$00              ; clear RAM to all zeros
  sta (MEM_POINTER),y
  iny
  beq next_page
  jmp loop_ram
next_page:
  lda MEM_POINTER + 1
  inc
  cmp #$40
  beq done_ram
  sta MEM_POINTER + 1
  jmp loop_ram

done_ram:

  lda #<mem_pass_msg
  sta MESSAGE_POINTER
  lda #>mem_pass_msg
  sta MESSAGE_POINTER + 1
  jsr lcd_clear
  jsr print 
  smb5 FLAGS
  jmp loop

mem_fail_1:

  lda #<mem_fail_msg_1
  sta MESSAGE_POINTER
  lda #>mem_fail_msg_1
  sta MESSAGE_POINTER + 1
  jsr print
  jmp loop

mem_fail_2:

  lda #<mem_fail_msg_2
  sta MESSAGE_POINTER
  lda #>mem_fail_msg_2
  sta MESSAGE_POINTER + 1
  jsr print
  jmp loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  
;;                 Main Loop
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loop:

  wai
  jsr check_flags
  jmp loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                  FUNCTIONS
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
  bcc @exit
  jsr block_address
  lda TICKS
  sta TOGGLE_TIME
@exit:
  rts

clock_time:

  sec
  lda TICKS
  sbc CLOCK_LAST
  cmp #$32
  bcc @exit
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
  lda #' '
  jsr print_char
  lda TICKS
  sta CLOCK_LAST
@exit:
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
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  lda DUMP_POINTER
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  lda #' '
  jsr print_char
  ldy #$00
  lda (DUMP_POINTER),y
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  lda #' '
  jsr print_char
  lda (DUMP_POINTER),y
  jsr print_char
  jsr print   ; add second line (cursor) after re-writing the top line
  rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      display 8 bytes of data for a "block" of memory
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

block_address:

  jsr lcd_clear
  ldy #$00
  lda #'$'
  jsr print_char
  lda DUMP_POINTER + 1
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  lda DUMP_POINTER
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  jsr lcd_line_2
@loop:
  lda (DUMP_POINTER),y
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  lda (DUMP_POINTER),y
  iny
  cpy #$08
  bne @loop
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;            print on line 1 or line 2
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print1:

  jsr lcd_clear
  ldy #0
  jmp line1
print:
  jsr lcd_line_2
  ldy #0
line1:
  lda (MESSAGE_POINTER),y
  beq @exit
  jsr print_char
  iny
  jmp line1
@exit:
  rts




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Monitor function - decrement the selected address 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Monitor function - increment the selected address 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

increment_address:

  clc
  lda DUMP_POINTER
  adc #$01
  sta DUMP_POINTER
  sta BYTE
  lda DUMP_POINTER + 1
  adc #$00
  sta DUMP_POINTER + 1
  sta BYTE + 1
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Monitor function - increment the selected block of  addresses by 8 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Monitor function - decrement the selected block of  addresses by 8 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; use last 4 key presses (as hex bytes) to fill two BYTES
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keys_byte:

  lda KEY_PRESS + 1
  asl
  asl
  asl
  asl
  sta BYTE
  lda KEY_PRESS
  ora BYTE
  sta BYTE  
  lda KEY_PRESS + 3
  asl
  asl
  asl
  asl
  sta BYTE + 1
  lda KEY_PRESS + 2
  ora BYTE + 1
  sta BYTE + 1
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    toggle the display/update of Clock on each appropriate keypress
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_clock:

  bbs5 FLAGS, reset_bit5
  smb5 FLAGS
  jmp exit_show_clock
reset_bit5:
  rmb5 FLAGS
exit_show_clock:
  rts
  


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    toggle the automatic update view of the "8-byte memory block"
;;

show_block:
  
  bbs0 FLAGS, reset_bit0
  smb0 FLAGS
  jmp exit_show_block
reset_bit0:
  rmb0 FLAGS
exit_show_block:
  rts
  
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;
;;                     INTERRUPT HANDLERS 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                 CB1 : reset & restart timer
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cb1_handler:

  stz HUNDRED_HRS
  stz TEN_HRS
  stz TEN_MINUTES
  stz TEN_SECONDS
  stz HRS
  stz MINUTES
  stz SECONDS
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                CB2 : lap-time pause timer
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cb2_handler:

  jsr show_clock
  rts
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                    MONITOR / KEYPAD 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

keypad_handler:

  jsr get_key     ; READs from PORTA which also re-sets VIA's Interrupt flag
  sta INKEY       ; put the byte value of input into RAM ( $00 )   
  lda PORTB_1       ; check for SHIFT/INSTRUCTION button
  and #%10000000
  beq check_keypress ; done this way to get around the limit in size of branch jumps....
  jmp handle_new_char
  
check_keypress:
  
  lda INKEY
  jsr bintohex  ; convert BYTE value of keypress to its ASCII HEX equivalent "0" -> "A"     

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
  ldy #$00
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
  jmp exit_key_irq

check_3:

  cmp #'3'
  bne check_6
  ldy #$00
  jsr increment_block
  jsr block_address
  jmp exit_key_irq

check_6:

  cmp #'6'
  bne check_9
  ldy #$00
  jsr decrement_block
  jsr block_address
  jmp exit_key_irq

check_9:

  cmp #'9'
  bne check_4
  jsr show_block
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
  jsr $3F00
  jmp exit_key_irq


handle_new_char:

  lda KEY_PRESS + 2
  sta KEY_PRESS + 3
  lda KEY_PRESS + 1
  sta KEY_PRESS + 2
  lda KEY_PRESS
  sta KEY_PRESS + 1
  lda INKEY       ; get the new keypress value and... 
  sta KEY_PRESS
  jsr bintohex 
  jsr print_char  ; and print it on LCD
  jsr keys_byte
 
exit_key_irq:

  jsr scan  ; re-enable keypad
  rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nmi:

  rti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    interrupt is triggered by HIGH edge on VIA CA1 pin
;;     PORTA low nibble (keypad columns) inputs are diode ORed to CA1
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
  bit T1CL_1      ; clear not clear = handle the TIMER interrupt
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

emt: .asciiz "Shed Time  MET"
splash: .asciiz "shed> "
error_message: .asciiz "Not Decimal"
mem_start_msg: .asciiz "Begin RAM Test"
mem_pass_msg: .asciiz "RAM Test Pass"
mem_fail_msg_1: .asciiz "RAM Test 1 Fail"
mem_fail_msg_2: .asciiz "RAM Test 2 Fail"

; Reset/IRQ vectors

.segment "VECTORS"
  
  .word nmi
  .word reset
  .word irq
