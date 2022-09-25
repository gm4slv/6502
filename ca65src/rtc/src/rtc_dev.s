;;


.zeropage

BEEP_POINTER:     .res 2
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
SPI_LAST:         .res 1
BEEP_ON_TIME:     .res 1
BEEP_DELAY_TIME:  .res 1 ; $01 = 1 tick ~10ms, $FF = 255 ticks ~2.5 seconds
SPI_BYTE:         .res 2
MAX_PAGE:         .res 2

.bss

INKEY:            .res 1
KEY_PRESS:        .res 4
BYTE:             .res 2
TENS:             .res 1
HUNDREDS:         .res 1
TEMP:             .res 2 ; 2 byte scratchpad
TEMP2:            .res 2 ; 2 byte scratchpad
HI_DIGIT:         .res 1
LO_DIGIT:         .res 1
VALUE:            .res 2
MOD10:            .res 2
num_message:      .res 6
SPIIN:            .res 1
SPIOUT:           .res 1
SPI_TX_BYTE:      .res 2
SPI_RX_BYTE:      .res 2

RTC_SEC:           .res 1
RTC_MIN:           .res 1
RTC_HRS:           .res 1
RTC_DAY:           .res 1
RTC_DATE:          .res 1
RTC_MONTH:         .res 1
RTC_YEAR:          .res 1


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
.include "../includes/spi_trx_mode3.inc"
.include "../includes/printval.inc"


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
  
  jsr via_1_init
  lda #%00000000  ; 
  sta IER_1       ; stop Keypad or buttons triggering interrupts until we're ready for them
  
  lda #%00000000  ; 
  sta DDRA_1      ; disable keypad until we're ready for it
  
  lda #%00000000
  sta ACR_2       ; disable VIA T1 driven beep noises until we're ready for them
  
  
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
  lda #$3F
  sta BEEP_POINTER
  lda #$03
  sta BEEP_POINTER + 1
  lda #$0A              ; standard BEEP = 10 ticks, ~100mS
  sta BEEP_DELAY_TIME
  stz TOGGLE_TIME
  stz CLOCK_LAST
  stz LED2_LAST
  stz SPI_LAST
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
  stz MOD10
  stz MOD10 + 1
  stz VALUE
  stz VALUE + 1
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    First Signs of Life
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  lda #<title
  sta MESSAGE_POINTER
  lda #>title
  sta MESSAGE_POINTER + 1
  jsr print1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Find extent of usable RAM
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

memory_count:

  lda #<mem_start_msg
  sta MESSAGE_POINTER
  lda #>mem_start_msg
  sta MESSAGE_POINTER + 1
  jsr print2
  
  
;; Write $55 to each memory location until it fails
;; to be read correctly = top of RAM area

;; Test between $0200 and $FFFF
  
  lda #$02            ; start at $0200
  sta MEM_POINTER + 1
  ldy #$00
  
count_loop_ram:

  lda #$55              ; test with 01010101
  sta (MEM_POINTER),y   ; write test value to RAM
  lda #$FF              ; remove test value from A
  lda (MEM_POINTER),y   ; read RAM contents into A
  cmp #$55                  
  bne count_done_ram    ; FAILS at first address after top of RAM

  iny
  beq count_next_page

  jmp count_loop_ram
  
count_next_page:

  lda MEM_POINTER + 1
  inc
  cmp #$FF            ; endstop page = top of 6502 Address Space!
  beq count_done_ram
  
  sta MEM_POINTER + 1
  jmp count_loop_ram

count_done_ram:

  sta MAX_PAGE        ; last successful RAM Page stored for
                      ; subsequent RAM clear end point

 ;; calculate total number of usable bytes in RAM ($0000 -> $[MEM_POINTER+1 MEM_POINTER] + y )

  tya
  clc
  adc MEM_POINTER
  sta VALUE           ; store for print_value function 
  sta MEM_POINTER     ; store for later
  lda MEM_POINTER + 1
  adc #0
  sta VALUE + 1       ; store for print_value function
  sta MEM_POINTER + 1 ; store for later
  clc
  
  jsr print_value     ; convert 2-bytes of VALUE into a decimal number of useable RAM bytes
  
  lda #<num_message   ; and print it
  sta MESSAGE_POINTER
  lda #>num_message
  sta MESSAGE_POINTER + 1
  jsr print4
  
  lda #' '
  jsr print_char
  lda #'B'
  jsr print_char
  lda #'y'
  jsr print_char
  lda #'t'
  jsr print_char
  lda #'e'
  jsr print_char
  lda #'s'
  jsr print_char
  
  lda #' '
  jsr print_char
  lda #'('
  jsr print_char
  lda #'$'
  jsr print_char
  
  sec               ; the actual "Top of RAM" found is the first UNusable byte, so we
  lda MEM_POINTER   ; want the "one before that" to show where the real "Top of RAM"
  sbc #$01          ; is, so subtract 1 from the 2-byte MEM_POINTER just arrived at above
  sta TEMP
  lda MEM_POINTER + 1
  sbc #$0
  sta TEMP + 1
  
  lda TEMP + 1
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char
  
  lda TEMP
  jsr bintohex
  lda HI_DIGIT
  jsr print_char
  lda LO_DIGIT
  jsr print_char

  lda #')'
  jsr print_char

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Clear RAM of the "$55" put in duing the Mem Count above. 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

memory_zero:
 
;; test then clear RAM between 
;; $0200 - $3FFF - avoids the ZP and STACK areas

  lda #$02            ; start at $0200
  sta MEM_POINTER + 1

  ldy #$00

loop_ram:

  lda #$00              ; clear RAM with 00000000
  sta (MEM_POINTER),y
  iny
  beq next_page

  jmp loop_ram
  
next_page:
  
  lda MEM_POINTER + 1
  inc
  cmp MAX_PAGE
  beq done_ram
  
  sta MEM_POINTER + 1
  jmp loop_ram

done_ram:

  lda #<mem_complete_msg
  sta MESSAGE_POINTER
  lda #>mem_complete_msg
  sta MESSAGE_POINTER + 1
  jsr print3 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  
;;      IOPORTS - re-initialize after MEM check.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  jsr via_1_init
  jsr via_2_init ; set-up VIA_2 for general I/O
  jsr via_3_init ; set-up VIA_3 for general I/O
 
  ;; now make a beep-boop
  jsr beep2
  
  ;smb5 FLAGS ; show Mission Time Clock on LCD2
  smb2 FLAGS ; start SPI TX/RX from VIA_2 port A
  
  jsr lcd_2_clear
  ;lda #<emt
  ;sta MESSAGE_POINTER
  ;lda #>emt
  ;sta MESSAGE_POINTER + 1
  ;jsr print2_2
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Put a sample program into "User Ram" at $3F00
;;
;;  Load the User RAM area at $3F00-> with the bytes 
;;  set in "userProg" - currently a small routine that
;;  changes the contents of MESSAGE_POINTER (+1) to point
;;  to $2000 instead. Then a string from "userPrompt" is stored
;;  at $2000. Running the user sub-routine (<shift>5) will now show
;;  the "userPrompt" string on line4 of the main LCD
;;  The user prog at $3F00 can be edited at will 
;;
;; 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

user_ram:

  ldy #$00
@loop:
  lda userProg,y
  beq @exit
  sta $3F00,y
  iny
  jmp @loop
@exit:

;; Put a sample text string @ $2000->

user_prompt:

  ldy #$00
@loop:
  lda userPrompt,y
  beq @exit
  sta $2000,y
  iny
  jmp @loop
@exit:
  lda #$00      ; plus a trailing NULL just in case....
  sta $2000,y

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  
;;                 Main Loop
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loop:

  wai
  jsr check_flags
  jmp loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                  FUNCTIONS
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;     FLAGS - for control of background tasks
;;
;;   bit7    | bit6   | bit5    |  bit4 | bit3 | bit2   | bit1 | bit0
;; ==========|========|=========|=======|======|========|======|===========
;;   beep    |        | spi(0)  |       |      | spi    |      | mem block
;;   sound   |        | or      |       |      | tx/rx  |      | view
;;   started |        | clock(1)|       |      | active |      | update
;;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_flags:

  ;; show FLAGS on LEDs, just for fun
  lda FLAGS
  sta PORTA_2

flag_zero:

  bbr0 FLAGS, flag_one
  jsr update_block_address

flag_one:

flag_two:

  bbr2 FLAGS, flag_three
  jsr spi_portb_3

flag_three:

flag_four:

flag_six:

flag_seven:

  bbr7 FLAGS, flag_five
  jsr check_beep

flag_five:

  bbr5 FLAGS, no_flag_five  
  jmp clock_time            ; (jsr/rts)
  ;rts
  
no_flag_five:

  jmp update_spi_monitor    ; (jsr/rts)
  ;rts
  
;;;;;;;;;;
;;;;;;;;;;
;;;
check_beep:

  sec
  lda TICKS
  sbc BEEP_ON_TIME
  cmp BEEP_DELAY_TIME
  bcc @exit
  jsr beep_off
@exit:
  rts

spi_portb_3:

  sec
  lda TICKS
  sbc SPI_LAST
  cmp #50 
  bcs spi_rtc
  rts
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;   RTC Update from DS1306 via SPI 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


spi_rtc:
  
  ;; CLOCK HIGH IDLE CPOL = 1
  ;; MODE 2 and MODE 3
  ;; PUT A BRANCH HERE TO MAKE SWAPPING MODES EASIER?
  ;;

  lda #SCK
  tsb SPI_PORT

;;;;;;;;;; CS Signal -> ACTIVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; for ds1306 rtc - CS is HIGH for active - unusual - is this correct?
  ;;

  lda #CS
  tsb SPI_PORT

;;;;;;;;; First Byte ;;;;;;;;;;;;;;;;;

  lda #$00
  jsr spi_transceive
  sta RTC_SEC ; will be bogus?

;; continue sending (data irrelavant) and reading sequential 
;; replies from RTC Chip containing BCD coded SEC/MIN/HRS... etc

  lda #$00
  jsr spi_transceive
  sta RTC_SEC
  jsr spi_transceive
  sta RTC_MIN
  jsr spi_transceive
  sta RTC_HRS
  jsr spi_transceive
  sta RTC_DAY
  jsr spi_transceive
  sta RTC_DATE
  jsr spi_transceive
  sta RTC_MONTH
  jsr spi_transceive
  sta RTC_YEAR
  
;;;;; CS signal -> IDLE ;;;;;;;;;;;;;;;;;
  
  ;;; for ds1306 CS is low for idle

  lda #CS
  trb SPI_PORT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  lda TICKS
  sta SPI_LAST
  
  rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  MANUAL SPI TRANSMIT

spi_tx_rx:

;; CLOCK HIGH IDLE CPOL = 1
  ;; MODE 2 and MODE 3
  ;; PUT A BRANCH HERE TO MAKE SWAPPING MODES EASIER?
  ;;

  lda #SCK
  tsb SPI_PORT

;;;;;;;;;; CS Signal -> ACTIVE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; for ds1306 rtc - CS is HIGH for active - unusual - is this correct?
  ;;

  lda #CS
  tsb SPI_PORT

  lda SPI_BYTE
  jsr spi_transceive
  
  lda SPI_BYTE + 1
  jsr spi_transceive
  
  lda #CS
  trb SPI_PORT
    
  rts
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;

update_spi_monitor:

  sec
  lda TICKS
  sbc CLOCK_LAST
  cmp #100
  bcs @do_update
  rts
  
@do_update:
  
  jsr lcd_2_cursor_off
  jsr lcd_2_clear
  
  jsr lcd_2_line_1
  


  
  
  lda RTC_DATE
  jsr bintohex_2
  
  lda #'/'
  jsr print_2_char
  
  lda RTC_MONTH
  jsr bintohex_2
  
  lda #'/'
  jsr print_2_char
  
  lda RTC_YEAR
  jsr bintohex_2
  
 

  
  lda #' '
  jsr print_2_char
  
  lda RTC_DAY
  sta TEMP + 3
  asl
  adc TEMP + 3
  tay
  ldx #3
@loopday:
  lda dowList,y
  jsr print_2_char
  iny
  dex
  bne @loopday
  
  
  jsr lcd_2_line_2
  
  lda RTC_HRS
  jsr bintohex_2
  
  lda #':'
  jsr print_2_char
  
  lda RTC_MIN
  jsr bintohex_2
  
  lda #':'
  jsr print_2_char
  
  lda RTC_SEC
  jsr bintohex_2
  
  lda TICKS
  sta CLOCK_LAST
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;

update_block_address:

  jsr lcd_line_2
  sec
  lda TICKS
  sbc TOGGLE_TIME
  cmp #100
  bcc @exit
  jsr block_address
  lda TICKS
  sta TOGGLE_TIME
@exit:
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;

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
  lda #' '
  jsr print_2_char
  lda #' '
  jsr print_2_char
  lda #' '
  jsr print_2_char
  lda #' '
  jsr print_2_char
  lda #' '
  jsr print_2_char
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
  lda #'$'
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
  
  lda #' '
  jsr print_char
  
  ;;;;;;;;;;;;;;
  ;;

  lda (DUMP_POINTER),y
  sta VALUE
  stz VALUE + 1
  jsr print_value
  lda #<num_message
  sta MESSAGE_POINTER
  lda #>num_message
  sta MESSAGE_POINTER + 1
  ldy #0
  jsr line
  
  ;;;;;;;;;;;;;;;;;;;;;

new_cursor:

  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1
  jmp print4   ; (jsr / rts)


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
  jsr print_char
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
  
  jmp print_char  ; (jsr / rts)

  ;jsr print_char
  ;rts



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
;;    toggle the display/update of SPI Monitor on LCD2
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clock_or_spi:

  bbs5 FLAGS, reset_bit5
  smb5 FLAGS
  lda #<emt
  sta MESSAGE_POINTER
  lda #>emt
  sta MESSAGE_POINTER + 1
  jsr print2_2
  jmp exit_clock_or_spi

reset_bit5:

  rmb5 FLAGS
  
exit_clock_or_spi:
  
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
;;     toggle the TX/RX of SPI on PORTB_2
;;

update_spi:
  
  bbs2 FLAGS, reset_bit2
  smb2 FLAGS
  jmp exit_update_spi

reset_bit2:

  rmb2 FLAGS
  stz PORTA_2

exit_update_spi:

  rts




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;
;;                     INTERRUPT HANDLERS 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;         reset & restart timer
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


reset_met:

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
;;                CB : TEST FUNCTIONS
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cb1_handler:

  lda #$05
  sta BEEP_DELAY_TIME

  jmp beep_from_pointer  ; (jsr/rts)
  ;nop
  rts
  
cb2_handler:

  lda #$40
  sta BEEP_DELAY_TIME
  lda #$02 ; tone # = 100Hz
 
  jmp beep_from_list    ; (jsr/rts)
  ;nop
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
  beq check_keypress; done this way to get around the limit in size of branch jumps....
  jsr beep_from_pointer
  jmp handle_new_char
  
check_keypress:
  
  lda INKEY
  
; choose action of "SHIFTed" key-press

check_a:
  
  cmp #$0A
  ; move up one memory address and display contents
  bne check_b     
  jsr increment_address
  jsr beep
  jsr new_address
  jmp exit_key_irq

check_b:

  cmp #$0B
  ; move down one memory address and display contents
  bne check_c
  jsr decrement_address
  jsr beep
  jsr new_address
  jmp exit_key_irq

check_c:

  cmp #$0C
  ; return to MONITOR
  bne check_d
  rmb0 FLAGS
  jsr lcd_clear  
  jsr beep
  jsr new_address
  jmp exit_key_irq

check_d:

  cmp #$0D
  ; move monitor to entered 4-digit memory address
  bne check_e
  lda BYTE
  sta DUMP_POINTER
  lda BYTE + 1
  sta DUMP_POINTER + 1
  jsr beep
  jsr new_address
  jmp exit_key_irq

check_e:

  cmp #$0E
  ; insert (POKE) byte of data in to current memory address, then increment to next address
  bne check_f
  lda BYTE
  ldy #$00
  sta (DUMP_POINTER),y
  jsr beep  
  jsr new_address
  jmp exit_key_irq

check_f:

  cmp #$0F
  ; show 8-byte wide block of memory
  bne check_1
  ldy #$00
  lda BYTE
  sta DUMP_POINTER
  lda BYTE + 1
  sta DUMP_POINTER + 1
  jsr beep
  jsr block_address
  jmp exit_key_irq

check_1:

  cmp #$01
  ; pause SPI Monitor on LCD2
  bne check_2
  jsr beep
  jsr clock_or_spi
  jmp exit_key_irq

check_2:

  cmp #$02
  ; reset_clock
  bne check_3
  jsr beep
  jsr reset_met
  jmp exit_key_irq

check_3:

  cmp #$03
  ; move up a block of 8
  bne check_6
  ldy #$00
  jsr increment_block
  jsr beep
  jsr block_address
  jmp exit_key_irq

check_6:

  cmp #$06
  ; move down a block of 8
  bne check_9
  ldy #$00
  jsr decrement_block
  jsr beep
  jsr block_address
  jmp exit_key_irq

check_9:

  cmp #$09
  ; show updating block of memory  
  bne check_4
  jsr beep
  jsr show_block
  jmp exit_key_irq

check_4:

  cmp #$04
  ; Input 2 new SPI TX Bytes
  bne check_5
  lda BYTE + 1  ; change from little-endian for SPI TX
  sta SPI_BYTE
  lda BYTE
  sta SPI_BYTE + 1
  jsr beep
  jsr spi_tx_rx
  jsr new_address
  jmp exit_key_irq

check_5:

  cmp #$05
  ; run user code at $3F00
  bne check_0
  jsr beep
  jsr $3F00
  jmp exit_key_irq

check_0:

  cmp #$00
  ; run/pause SPI TX & RX
  bne exit_key_irq
  jsr beep
  jsr update_spi
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

  jmp scan    ; (jsr/rts)
  
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

  lda IFR_1       ; if IFR_1 has Bit7 set (ie sign=NEGATIVE) then it IS the source of the interrupt
  bpl via2_device ; if it's not set (ie sign=POSITIVE) then branch to test the next possible device

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


via2_device:
  lda IFR_2
  bpl via3_device
  
test_cb1_2:
  asl
  asl
  asl
  asl
  bcc test_cb2_2
  bit PORTB_2
  jsr cb1_handler
  jmp exit_irq
  
test_cb2_2:
  asl
  bcc exit_irq
  bit PORTB_2
  jsr cb2_handler
  jmp exit_irq

via3_device:
  lda IFR_3
  bpl next_device
  
test_cb1_3:
  asl
  asl
  asl
  asl
  bcc test_cb2_3
  bit PORTB_3
  jsr cb1_handler
  jmp exit_irq
  
test_cb2_3:
  asl
  bcc exit_irq
  bit PORTB_3
  jsr cb2_handler
  jmp exit_irq

next_device:

exit_irq:

  ply
  plx
  pla
  rti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      String and data byte variables
;;
;;
;;

;pause_msg: .asciiz "Mark Time     "
start_msg: .asciiz "<shift>+C to start"
new_address_msg: .asciiz "$addr $dd C Dec"
;new_address_msg: .asciiz "View/Edit Memory"
block_address_msg: .asciiz "8 Byte view"
title: .asciiz "...Shed Brain v1..."
emt: .asciiz "Mission Time    "
splash: .asciiz "shed> "
mem_start_msg: .asciiz "Begin RAM Test"
mem_pass_msg: .asciiz "RAM Test Pass"
mem_complete_msg: .asciiz "Memory Test Complete"

dowList: .byte "xxxMonTueWedThuFriSatSun"

userPrompt: .asciiz "This is shed! "

userProg: .byte $64, MESSAGE_POINTER, $A9, $20, $85, MESSAGE_POINTER + 1, $20, <print4, >print4, $60, $00

kitLeds: .byte $01, $03, $06, $0C, $18, $30, $60, $C0, $80, $C0, $60, $30, $18, $0C, $06, $03, $01


; Reset/IRQ vectors

.segment "VECTORS"
  
  .word nmi
  .word reset
  .word irq
