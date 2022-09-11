

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




.code


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
  stz LAST_KIT
  
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;      String and data byte variables
;;
;;
;;

pause_msg: .asciiz "Mark Time     "
start_msg: .asciiz "<shift>+C to start"
new_address_msg: .asciiz "View/Edit Memory"
block_address_msg: .asciiz "8 Byte view"
title: .asciiz "...Shed Brain v1..."
emt: .asciiz "Shed Time  MET"
splash: .asciiz "shed> "
mem_start_msg: .asciiz "Begin RAM Test"
mem_pass_msg: .asciiz "RAM Test Pass"
mem_fail_msg_1: .asciiz "RAM Test 1 Fail"
mem_fail_msg_2: .asciiz "RAM Test 2 Fail"

userPrompt: .asciiz "This is shed! "

userProg: .byte $64, $05, $A9, $20, $85, $06, $20, <print4, >print4, $60, $00

kitLeds: .byte $01, $03, $06, $0C, $18, $30, $60, $C0, $80, $C0, $60, $30, $18, $0C, $06, $03, $01

