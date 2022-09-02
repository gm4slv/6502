; VIA Port addresses
PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

T1CL = $6004
T1CH = $6005

ACR = $600b
PCR = $600c
IFR_1 = $600d
IER = $600e

; LCD Command masks
E  = %01000000
RW = %00100000
RS = %00010000

  .org $8000

BASE_ADDRESS = $0000

; Zero Page variables
; $00 = DUMP_POINTER
; $01 = DUMP_POINTER + 1
; $02 = INKEY
; $03 = TEMP
; $04 = MESSAGE_POINTER
; $05 = MESSAGE_POINTER + 1
; $06 = ASCII
; $07 = ASCII + 1
; $08 = ASCII + 2
; $09 = ASCII + 3
; $0A = BYTE
; $0B = BYTE + 1
; $0C = TICKS
; $0D = TICKS + 1
; $0E = TICKS + 2
; $0F = TICKS + 3
; $10 = TOGGLE_TIME
; $11 = FLAG
; $12 = CLOCK_LAST
; $20 = CENTISEC
; $21 = SECONDS
; $22 = MINUTES
; $23 = HRS
; $24 = DAY
; $25 = MO
; $26 = YR
; $27 = TENS
; $28 = HUNDREDS
; $30 = HEX
; $31 = SPARE
; $32 = HEXB
; $33 = HEXB + 1


DUMP_POINTER = $00

INKEY = $02

TEMP = $03

MESSAGE_POINTER = $04

ASCII = $06        ; 4-bytes rolling store of entered key-press characters in ASCII

BYTE = $0A        ; binary representation of entered key-presses - 2 bytes

TICKS = $0C       ; 4-bytes = 32 bits

TOGGLE_TIME = $10

FLAGS = $11 ; bit0 = update block memory view, bit5 = show clock

CLOCK_LAST = $12

CENTISEC = $20
SECONDS = $21
MINUTES = $22
HRS = $23
DAY = $24
;MO = $25
;YR = $26

TENS = $27
HUNDREDS = $28
HEX = $30 ; 2 bytes
HEXB = $32 ; 2 bytes

reset:
  ldx #$ff
  txs
;; IFR Flags
;; B7  B6  B5  B4  B3  B2  B1  B0
;; IRQ TI1 TI2 CB1 CB2 SR CA1 CA2
  
  lda #%11011010  ; T1, CA1 active
  sta IER
  

  lda #$01  ;  CA1 active high-transition 
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

  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1

  lda #<BASE_ADDRESS
  sta DUMP_POINTER
  lda #>BASE_ADDRESS
  sta DUMP_POINTER + 1


init_timer:
  stz TICKS
  stz TICKS + 1
  stz TICKS + 2
  stz TICKS + 3
  stz TOGGLE_TIME
  stz FLAGS
  stz SECONDS
  stz MINUTES
  stz HRS
  stz DAY
  ;stz MO
  ;stz YR
  stz TEMP
  stz TENS
  lda #%01000000
  sta ACR
  lda #$0E
  sta T1CL
  lda #$27
  sta T1CH

user_ram_fill:
  lda #$ea
  ldx #$ff
fill:
  sta $3000,x
  dex
  bne fill
  stz $3000
  lda #$60
  sta $30ff

; show the clock at startup 
  ;smb5 FLAGS
  jsr new_address

; main loop
loop:
  jsr check_flags
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
  lda #%00001100 ; Display on; cursor on; blink off
  jsr lcd_instruction
  
  lda #%00000010 ; cursor HOME
  jsr lcd_instruction
  lda DAY
  jsr bintoascii
  lda #"/"
  jsr print_char
  lda HRS
  jsr bintoascii
  lda #":"
  jsr print_char
  lda MINUTES
  jsr bintoascii
  lda #":"
  jsr print_char
  lda SECONDS
  jsr bintoascii
  ;lda #":"
  ;jsr print_char
  ;lda CENTISEC
  ;jsr bintoascii
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
  
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  lda #%00001111 ; Display on; cursor on; blink off
  jsr lcd_instruction


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

  ldy #$00

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
;;
;; display 8 bytes of data for a "block" of memory
;;
;;
block_address:
  
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  ldy #$00

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
;;
;; re-draw line 2 cursor
;;
;;
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  set ROW keypad outputs high as a source for triggering interrupt when a key is pressed
;;
;;
scan:
  ldy #%11110000
  sty PORTA
  rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      Convert a decimal number entered at keypad into its
;;      HEX equivalent and display
;;
byte_to_hex:
  
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  lda HEXB + 1
  and #$0f
  jsr bintohex
  lda HEXB
  jsr bintohex
  lda #"d"
  jsr print_char
  lda #"="
  jsr print_char
  lda #"$"
  jsr print_char

  lda HEXB ; lo byte
  pha
  lsr
  lsr
  lsr
  lsr
  jsr mult10
  sta TENS
  pla
  and #%00001111 ; UNITS
;  jsr mult10
  clc
  adc TENS
  sta HEX
  
  lda HEXB + 1 ; hi byte
  and #%00001111
  jsr mult10
  jsr mult10 ; hundreds
  adc HEX
  

  jsr bintohex
  lda #%10101001
  jsr lcd_instruction
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  (A * 8) + (A * 2) = A * 10 

mult10:
  pha
  asl
  asl
  asl
  sta TEMP ; A*8
  pla
  asl      ; A*2
  adc TEMP ; A*10
  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;          convert a binary number from Accumulator, in range 00000000 -> 11111111 ($00 to $FF)
;;          to its HEX number encode as ASCII -  using a simple lookup table and print it on LCD
;;
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    convert a binary (hex) value in Accumulator into 
;;    its ASCII equivalent character in decimal 0-99 and print it
;;    this converts hex/binary numbers from the RTC into human readable
;;    decimal for display on clock


bintoascii:
  asl
  tax
  lda binascii,x
  jsr print_char

  inx
  lda binascii,x
  jsr print_char
  rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;                              LCD Functions 
;;
;;
;;
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   
;;        PRINT Characters on LCD - an ASCII value in Accumulator 
;;        is printed on the display
;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
  bcc inc_ok
  inc DUMP_POINTER + 1
  lda DUMP_POINTER + 1
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

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Convert the encoded ASCII character representing a hex digit to its actual binary value.
;;
;; e.g. Letter "A" in ASCII is $41 (0100001) but its "numerical" value as a hex digit is 
;; 10 ($0A = 10d). 
;; 
;; We convert "A" in ASCII ($41) to a byte of numerical value 10 by subtracting $37
;; $41 - $37 = $0A (in decimal 65 - 55 = 10) and the result is a byte 00001010
;; The same is done for all characters representing upper case letters.
;;
;; Numbers are handled differently according to their place on the ASCII table.
;;
;; The ASCII representation of "9" is $39 (00111001) and to get a byte with a value of 9 we can simply
;; AND it with a mask of 00001111 to save only the lower 4 bits.
;;
  
ascii_bin:
  clc  
  cmp #$41
  bmi ascii_bin_num   ; a CMP with $41, from a number character ($30 - $39), will set the negative flag
                      ; and the conversion is done by ANDing with $0F

ascii_bin_letter:    ; otherwise treat as a letter (A -> F) and the conversion is done by
  clc                ; subtracting $37
  sec
  sbc #$37
  jmp end_ascii_bin

ascii_bin_num:
  and #%00001111

end_ascii_bin:      ; Accumulator holds the numerical version of the ASCII character supplied
  rts 



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;    toggle the display/update of Clock on each appropriate keypress
;;
show_clock:
  
  bbs5 FLAGS, reset_bit5
  smb5 FLAGS
  jmp exit_show_clock

reset_bit5:

  rmb5 FLAGS

exit_show_clock:
  
  rts
  ;jmp debounce


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
  stz HRS
  stz MINUTES
  stz SECONDS
  smb5 FLAGS

  rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;     CB2 : stop timer
;;

cb2_handler:
  jsr show_clock
  rts
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                    MONITOR / KEYPAD 
;;
;;

keypad_handler:

  jsr get_key     ; READs from PORTA which also re-sets VIA's Interrupt flag
  sta INKEY       ; put the ASCII value of input into RAM ( $00 ) 
  
  lda PORTB       ; check for SHIFT/INSTRUCTION button
  and #%10000000
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
  jmp exit_key_irq

check_b:
  cmp #"B"
  ; move down one memory address and display contents
  bne check_c
  jsr decrement_address
  jsr new_address
  jmp exit_key_irq

check_c:
  cmp #"C"
  ; return to MONITOR
  bne check_d
  rmb5 FLAGS
  lda #%00000001
  jsr lcd_instruction
  lda #<splash
  sta MESSAGE_POINTER
  lda #>splash
  sta MESSAGE_POINTER + 1
  
  jsr new_address
  jmp exit_key_irq

check_d:
  cmp #"D"
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
  cmp #"E"
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
  cmp #"F"
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
  cmp #"1"
  ; show/auto-update clock
  bne check_3
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  lda #<emt
  sta MESSAGE_POINTER
  lda #>emt
  sta MESSAGE_POINTER + 1
  jsr print
  jsr show_clock
  jmp exit_key_irq

check_3:
  cmp #"3"
  bne check_6
  ldy #$00
  jsr increment_block
  jsr block_address
  jmp exit_key_irq

check_6:
  cmp #"6"
  bne check_9
  ldy #$00
  jsr decrement_block
  jsr block_address
  jmp exit_key_irq

check_9:
  cmp #"9"
  bne check_4
  jsr show_block
  jmp exit_key_irq

check_4:
  cmp #"4"
  bne check_5
  lda BYTE
  sta HEXB
  lda BYTE + 1
  sta HEXB + 1
  jsr byte_to_hex
  jmp exit_key_irq

check_5:
  cmp #"5"
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                          RTC / Jiffy Tick
;;

timer1_handler:


;;  RTC stores ticks at 10ms intervals into a 4-byte (32 bit) value
;;
;;  as each byte rolls over the next one is incremented
;;  on a tick that doesn't roll over the TIME OF DAY 
;;  is updated

  inc TICKS
  bne inc_TOD
  inc TICKS + 1
  bne inc_TOD
  inc TICKS + 2
  bne inc_TOD
  inc TICKS + 3

;;
;;  Every time it's called we increment the "hundredths of a second" byte
;;
;;  When there's been 100 x 10ms (i.e. 1 second) we increment the seconds
;;
;;  When SECONDS reaches 60 we increment MINUTES and reset SECONDS to zero...
;;  etc... for HOURS, DAYS etc.
;;
;;  days/months years are handled too - although probably moot
;;
;;  this routine comes from http://wilsonminesco.com/6502interrupts/#2.1
;;
inc_TOD:
  inc CENTISEC
  lda CENTISEC
  cmp #100
  bmi end_TOD
  stz CENTISEC

  inc SECONDS
  lda SECONDS
  cmp #60
  bmi end_TOD
  stz SECONDS

  inc MINUTES
  lda MINUTES
  cmp #60
  bmi end_TOD
  stz MINUTES

  inc HRS
  lda HRS
  cmp #24
  bmi end_TOD
  stz HRS

  inc DAY

  ;lda MO
  ;cmp #2
  ;bne notfeb

  ;lda YR
  ;and #%11111100
  ;cmp YR
  ;bne notfeb

  ;lda DAY
  ;cmp #30
  ;beq new_mo
  ;pla
  ;rts
;notfeb:
  ;phx
  ;ldx MO
  ;lda MO_DAYS_TABLE-1,x
  ;plx
  ;cmp DAY
  ;bne end_TOD
;new_mo:
  ;lda #1
  ;sta DAY
  ;inc MO
  ;lda MO
  ;cmp #13
  ;bne end_TOD
  ;lda #1
  ;sta MO

  ;inc YR
end_TOD:
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
  bit T1CL      ; clear not clear = handle the TIMER interrupt
  jsr timer1_handler
  jmp exit_irq

test_cb1:
  asl
  asl
  bcc test_cb2
  bit PORTB
  jsr cb1_handler
  jmp exit_irq

test_cb2:
  asl
  bcc test_ca1
  bit PORTB
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

emt: .asciiz "DD hh mm ss  MET"
splash: .asciiz "shack> "
keypad_array: .byte "?DCBAF9630852E741"
hexascii: .byte "0123456789ABCDEF"
binascii: .byte "00010203040506070809"
          .byte "10111213141516171819"
          .byte "20212223242526272829"
          .byte "30313233343536373839"
          .byte "40414243444546474849"
          .byte "50515253545556575859"
          .byte "60616263646566676869"
          .byte "70717273747576777879"
          .byte "80818283848586878889"
          .byte "90919293949596979899"
MO_DAYS_TABLE: .byte 32,  29,  32,  31,  32,  31,  32,  32,  31,  32,  31,  32



; Reset/IRQ vectors
  .org $fffa
  .word nmi
  .word reset
  .word irq
