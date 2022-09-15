;;;;;;;;;;;;;;;;;;;
;;
;;    Initial Bit-banging SPI transmit 
;;    from Ben Eater's video
;;
;;    each TX bit is individually coded....
;;
;;    nothing is done to read from MISO yet


.code


SCK   = %00000001
MOSI  = %00000010
CS    = %00000100
MISO  = %01000000



send_spi:

  lda #CS ; set CS high
  sta PORTA_2
  lda #00000111
  sta DDRA_2

;; bitbang

;; for testing with PyBoard SPI Slave
;; send 2 ASCII-coded bytes

;; sending e.g. '3'  '3' 
;;
;; i.e. send: $33 $33 (ASCII bytes for '3' '3')
;;
;; PyBoard replies with 'X' '6' (i.e. $58 $36)  and toggles LED #3
;;
;; sending '9' '1'
;;
;; PyBoard replies with 'X' ($58),  'B' ($42)
;; 
;; the letter 'B' is ASCII $42/66d and comes from doubling the '9' = ASCII $39/57d. The "doubling" is
;; calculated by converting the ASCII value (57d) to its numerical value (9d) by subtracting
;; 48d. Then multiplying by 2 (2*9 = 18) and then converting back to ASCII by adding 48d (which is
;; only appropriate to convert a number to its ASCII character)
;;
;; ((57 - 48) * 2 + 48) but of course this doesn't work for numbers over 5..... you get an ASCII
;; letter, instead. Good enough for testing....

;;   and toggles LED #1 (RED)


;; send first byte $39 = ASCII '9'


  lda #0
  sta PORTA_2  ; sets CS low as well as MOSI and SCK
  lda #SCK
  sta PORTA_2  ; sets SCK high
  
  lda #0
  sta PORTA_2
  lda #SCK
  sta PORTA_2 
  
  lda #MOSI
  sta PORTA_2
  lda #(SCK | MOSI)
  sta PORTA_2
  
  
  lda #MOSI
  sta PORTA_2
  lda #(SCK | MOSI)
  sta PORTA_2
  
 
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  

  
  lda #MOSI
  sta PORTA_2
  lda #(SCK | MOSI)
  sta PORTA_2
  
  lda #0
  sta PORTA_2
  lda #SCK
  sta PORTA_2 
  
  lda #0
  sta PORTA_2
  lda #SCK
  sta PORTA_2

  lda #MOSI
  sta PORTA_2
  lda #(SCK | MOSI)
  sta PORTA_2
  
  
  
  
  
;; send second byte $31 =  ASCII '1'

lda #0
  sta PORTA_2
  lda #SCK
  sta PORTA_2
  
  lda #0
  sta PORTA_2
  lda #SCK
  sta PORTA_2 
  
  lda #MOSI
  sta PORTA_2
  lda #(SCK | MOSI)
  sta PORTA_2
  
  
  lda #MOSI
  sta PORTA_2
  lda #(SCK | MOSI)
  sta PORTA_2
  
 ;;;;;;;;;;;;;;;;;;;;;
    
 lda #0
  sta PORTA_2
  lda #SCK
  sta PORTA_2
  
  lda #0
  sta PORTA_2
  lda #SCK
  sta PORTA_2
  
  lda #0
  sta PORTA_2
  lda #SCK
  sta PORTA_2
  
  lda #MOSI
  sta PORTA_2
  lda #(SCK | MOSI)
  sta PORTA_2

  
  lda #CS   ; everthing low except CS, which is now High until we're called again.
  sta PORTA_2
  
  rts
  

