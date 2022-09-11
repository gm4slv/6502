;;
;; DEV updates:
;;
;;1) pre-load USER MEM @ user_ram
;;
;;2) set new VIAs for OUTPUT on both ports A & B
;;
;;3) TESTING new VIAS with flashing LEDs on all ports
;;
;;4) Add second LCD on VIA_2 PORTA_2 ?

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
LED2_LAST:        .res 1
LED3_LAST:        .res 1
LAST_KIT:         .res 1

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
.include "../includes/lcd_2.inc"
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
  
  ;; IOPORTS
  jsr via_1_init ; set-up VIA_1 for LCD/Keypad 
  jsr via_2_init ; set-up VIA_2 for general I/O
  jsr via_3_init ; set-up VIA_3 for general I/O

  ;; LCD 
  jsr lcd_start ; set-up various features of lcd 
  jsr lcd_2_start ; set-up various features of lcd 

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
  stz LED2_LAST
  stz LED3_LAST
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
  lda #$10
  sta LAST_KIT
  lda #<title
  sta MESSAGE_POINTER
  lda #>title
  sta MESSAGE_POINTER + 1
  jsr print1

memory_test:

  lda #<mem_start_msg
  sta MESSAGE_POINTER
  lda #>mem_start_msg
  sta MESSAGE_POINTER + 1
  jsr print2
  
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
  ;jsr lcd_clear
  jsr print3 
  smb5 FLAGS
  lda #<start_msg
  sta MESSAGE_POINTER
  lda #>start_msg
  sta MESSAGE_POINTER + 1
  jsr print4
  jsr lcd_2_clear
  lda #<emt
  sta MESSAGE_POINTER
  lda #>emt
  sta MESSAGE_POINTER + 1
  jsr print2_2
  jmp user_ram

mem_fail_1:

  lda #<mem_fail_msg_1
  sta MESSAGE_POINTER
  lda #>mem_fail_msg_1
  sta MESSAGE_POINTER + 1
  jsr print3
  jmp loop

mem_fail_2:

  lda #<mem_fail_msg_2
  sta MESSAGE_POINTER
  lda #>mem_fail_msg_2
  sta MESSAGE_POINTER + 1
  jsr print3
  jmp loop



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    Put NOPs in the "user ram" area $3F00 -> $3F0A
;;    This is better than leaving this area full of $00, which is
;;    the BRK command, and causes problems when the "GO" function is
;;    done before putting any user code at $3F00.
;;
;;    Put a "guardian" RTS ($60) instruction at $3F0A to 
;;    catch any accidental use of the "GO" <shift>-5 command
;; 
;;    Copy the current address of the "print4" function into sequential bytes,
;;    $3F10 and $3F11, beyond the "guardian RTS", just to allow it to be found easily when
;;    writing user code that might want to print something on Line 4
;;    i.e.  "jsr print4" - look in $3F10 and £3F11 to see what 2 bytes are 
;;    needed to make the jsr target.
;;
user_ram:
  ldy #$00
@loop:
  lda userProg,y
  beq @exit
  sta $3F00,y
  iny
  jmp @loop
@exit:

prompt:
  ldy #$00
@loop:
  lda userPrompt,y
  beq @exit
  sta $2000,y
  iny
  jmp @loop
@exit:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  
;;                 Main Loop
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loop:

  wai
  ;jsr clock_time
  ;jsr clock_via_2
  ;jsr kit_led_via_3
  jsr check_flags
  jmp loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                  FUNCTIONS
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_flags:

flag_zero:
  bbr0 FLAGS, flag_two
  jsr update_block_address
  ;bbs5 FLAGS, clock_time_flag:
flag_two:
  bbr2 FLAGS, flag_five
  jsr kit_led_via_3
flag_five:
  bbr5 FLAGS, flag_null
  jsr clock_time
flag_null:
  ; check other flags... other actions....
  rts



kit_led_via_3:

  sec
  lda TICKS
  sbc LED3_LAST
  cmp #10
  bcc exit_kit_leds
  ldy LAST_KIT
  lda kitLeds,y
  sta PORTB_3
  dey
  bne @exit 
  ldy #$10
  sty LAST_KIT
@exit:
  sty LAST_KIT
  lda TICKS
  sta LED3_LAST
exit_kit_leds:
  rts

clock_via_2:
  sec
  lda TICKS
  sbc LED2_LAST
  cmp #100
  bcc exit_clock_via_2
  lda TEN_SECONDS
  asl
  asl
  asl
  asl
  ora SECONDS
  sta PORTA_2

  lda TEN_MINUTES
  asl
  asl
  asl
  asl
  ora MINUTES
  sta PORTB_2


;  inc PORTB_3
;  bne @exit
;  inc PORTA_2
;  bne @exit
;  inc PORTB_2
@exit:
  lda TICKS
  sta LED2_LAST
exit_clock_via_2:
  rts


update_block_address:
  jsr lcd_line_2
  sec
  lda TICKS
  sbc TOGGLE_TIME
  cmp #$64
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
  cmp #50
  bcc @exit
  jsr lcd_2_cursor_off
  jsr lcd_2_line_1
  lda HUNDRED_HRS
  jsr bintoascii_2
  lda TEN_HRS
  jsr bintoascii_2
  lda HRS
  jsr bintoascii_2
  lda #':'
  jsr print_2_char
  lda TEN_MINUTES
  jsr bintoascii_2
  lda MINUTES
  jsr bintoascii_2
  lda #':'
  jsr print_2_char
  lda TEN_SECONDS
  jsr bintoascii_2
  lda SECONDS
  jsr bintoascii_2
  lda #' '
  jsr print_2_char
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
  lda #<new_address_msg
  sta MESSAGE_POINTER
  lda #>new_address_msg
  sta MESSAGE_POINTER + 1
  jsr print1
  jsr lcd_line_2
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
  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1
  jsr print3   ; add second line (cursor) after re-writing the top line
  rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      display 8 bytes of data for a "block" of memory
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

block_address:

  jsr lcd_clear
  jsr lcd_cursor_off
  lda #<block_address_msg
  sta MESSAGE_POINTER
  lda #>block_address_msg
  sta MESSAGE_POINTER + 1
  jsr print1
  jsr lcd_line_2
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
  jsr lcd_line_3
loop1:
  lda (DUMP_POINTER),y
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  lda (DUMP_POINTER),y
  iny
  cpy #$08
  bne loop1
  lda #' '
  jsr print_char
  lda #'H'
  jsr print_char
  lda #'e'
  jsr print_char
  lda #'x'
  jsr print_char
  jsr lcd_line_4
  ldy #$00
loop2:
  lda #$20
  jsr print_char
  lda (DUMP_POINTER),y
  ;jsr bintohex
  ;lda HI_DIGIT
  jsr print_char
  ;lda LO_DIGIT
  ;jsr print_char
  ;lda (DUMP_POINTER),y
  iny
  cpy #$08
  bne loop2
  lda #' '
  jsr print_char
  lda #'C'
  jsr print_char
  lda #'h'
  jsr print_char
  lda #'r'
  jsr print_char
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;            print on line 1 or line 2
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
  lda #<emt
  sta MESSAGE_POINTER
  lda #>emt
  sta MESSAGE_POINTER + 1
  jsr print2_2
  jmp exit_show_clock
reset_bit5:
  rmb5 FLAGS
  lda #<pause_msg
  sta MESSAGE_POINTER
  lda #>pause_msg
  sta MESSAGE_POINTER + 1
  jsr print2_2

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
  
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;     toggle the scanning LED routine on VIA_3 Port B
;;

show_kitt:
  
  bbs2 FLAGS, reset_bit2
  smb2 FLAGS
  jmp exit_show_kitt
reset_bit2:
  rmb2 FLAGS
exit_show_kitt:
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
;;                CB2 : show/hide KITT scanning LEDs
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
  lda PORTB_1       ; check for SHIFT/INSTRUCTION button, 0=pressed, 1=not pressed
  and #%10000000    ; zero (eq) when button pressed -> check_keypress, otherwise it's not zero, jmp to handle_new_char
  beq check_keypress ; done this way to get around the limit in size of branch jumps....
  jmp handle_new_char
  
check_keypress:
  
  lda INKEY
  ;jsr bintohex  ; convert BYTE value of keypress to its ASCII HEX equivalent "0" -> "A"     
                 ; could perhaps not do this conversion, and checks below made against 
                 ; actual BYTE values?
                
                
; choose action of "SHIFTed" key-press

check_a:
  
  ;cmp #'A'
  cmp #$0A
  ; move up one memory address and display contents
  bne check_b     
  jsr increment_address
  jsr new_address
  jmp exit_key_irq

check_b:

  ;cmp #'B'
  cmp #$0B
  ; move down one memory address and display contents
  bne check_c
  jsr decrement_address
  jsr new_address
  jmp exit_key_irq

check_c:

  ;cmp #'C'
  cmp #$0C
  ; return to MONITOR
  bne check_d
  ;rmb5 FLAGS
  rmb0 FLAGS
  jsr lcd_clear
  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1  
  jsr new_address
  jmp exit_key_irq

check_d:

  ;cmp #'D'
  cmp #$0D
  ; move monitor to entered 4-digit memory address
  bne check_e
  lda BYTE
  sta DUMP_POINTER
  lda BYTE + 1
  sta DUMP_POINTER + 1
  jsr new_address
  ;jsr print2
  jmp exit_key_irq

check_e:

  ;cmp #'E'
  cmp #$0E
  ; insert (POKE) byte of data in to current memory address, then increment to next address
  bne check_f
  lda BYTE
  ldy #$00
  sta (DUMP_POINTER),y
  ;jsr increment_address
  jsr new_address
  ;jsr print2
  jmp exit_key_irq

check_f:

  ;cmp #'F'
  cmp #$0F
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

  ;cmp #'1'
  cmp #$01
  bne check_3
  jmp exit_key_irq

check_3:

  ;cmp #'3'
  cmp #$03
  bne check_6
  ldy #$00
  jsr increment_block
  jsr block_address
  jmp exit_key_irq

check_6:

  ;cmp #'6'
  cmp #$06
  bne check_9
  ldy #$00
  jsr decrement_block
  jsr block_address
  jmp exit_key_irq

check_9:

  ;cmp #'9'
  cmp #$09
  bne check_4
  jsr show_block
  jmp exit_key_irq

check_4:

  ;cmp #'4'
  cmp #$04
  bne check_5
  jsr show_kitt
  jmp exit_key_irq

check_5:

  ;cmp #'5'
  cmp #$05
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
  pha
  phx
  phy

  bit T1CL_3      ; reset interrupt flag
  jsr rtc
  jmp exit_nmi

exit_nmi:
  ply
  plx
  pla
  rti
  
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

;test_timer1:

;  asl           ; shift IFR left twice puts the TI1 bit into CARRY....
;  asl
;  bcc test_cb1  ; carry clear = next test
;  bit T1CL_1      ; clear not clear = handle the TIMER interrupt
;  jsr rtc
;  jmp exit_irq

test_cb1:

  asl
  asl
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

pause_msg: .asciiz "Mark Time     "
start_msg: .asciiz "<shift>+C to start"
new_address_msg: .asciiz "View/Edit Memory"
block_address_msg: .asciiz "8 Byte view"
title: .asciiz "...Shed Brain v1..."
emt: .asciiz "Shed Time  MET"
splash: .asciiz "shed> "
;error_message: .asciiz "Not Decimal"
mem_start_msg: .asciiz "Begin RAM Test"
mem_pass_msg: .asciiz "RAM Test Pass"
mem_fail_msg_1: .asciiz "RAM Test 1 Fail"
mem_fail_msg_2: .asciiz "RAM Test 2 Fail"
userPrompt: .asciiz "This is shed"
userProg: .byte $64, $05, $A9, $20, $85, $06, $20, <print4, >print4, $60, $00

kitLeds: .byte $01, $03, $06, $0C, $18, $30, $60, $C0, $80, $C0, $60, $30, $18, $0C, $06, $03, $01
; Reset/IRQ vectors

.segment "VECTORS"
  
  .word nmi
  .word reset
  .word irq
