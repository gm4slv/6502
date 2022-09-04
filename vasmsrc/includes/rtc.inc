

;.SEGMENT "ZEROPAGE"

  


  .org $8000

  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                          RTC / Jiffy Tick
;;



rtc:


;;  RTC stores ticks at 10ms intervals into a 4-byte (32 bit) value
;;
;;  as each byte rolls over the next one is incremented
;;  on a tick that doesn't roll over the TIME OF DAY 
;;  is updated

  inc TICKS
  bne inc_MET
  inc TICKS + 1
  bne inc_MET
  inc TICKS + 2
  bne inc_MET
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
inc_MET:
  inc CENTISEC
  lda CENTISEC
  cmp #100
  bmi end_MET
  stz CENTISEC

  inc SECONDS
  lda SECONDS
  cmp #10
  bmi end_MET
  stz SECONDS
  
  inc TEN_SECONDS
  lda TEN_SECONDS
  cmp #6
  bmi end_MET
  stz TEN_SECONDS

  inc MINUTES
  lda MINUTES
  cmp #10
  bmi end_MET
  stz MINUTES

  inc TEN_MINUTES
  lda TEN_MINUTES
  cmp #6
  bmi end_MET
  stz TEN_MINUTES

  inc HRS
  lda HRS
  cmp #10
  bmi end_MET
  stz HRS

  inc TEN_HRS
  lda TEN_HRS
  cmp #10
  bmi end_MET
  stz TEN_HRS

  inc HUNDRED_HRS

end_MET:
  rts

