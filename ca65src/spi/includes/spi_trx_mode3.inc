;;;;;;;;;;;;;;;;;;;
;;
;;    from Ben Eater's video
;;

.code


SCK   = %00000001
MOSI  = %00000010
CS    = %00000100
MISO  = %01000000

spi_transceive:
  
  stz SPIIN  
  sta SPIOUT
  
  ldy #08
  
  lda #MOSI

spi_loop:
  
  clc
  asl SPIOUT
  bcs spi_1
  trb SPI_PORT
  jmp spi_2

spi_1:
  
  tsb SPI_PORT

spi_2:
  
  ;; MODE 1 & Mode 3
  ;; CPHA 1 = read on falling edge
  ;; PUT A BRANCH HERE TO MAKE SWAPPING MODES EASIER?
  
  dec SPI_PORT
  
  bit SPI_PORT
  clc
  bvc spi_3
  sec

spi_3:
  
  rol SPIIN
  
  ;; MODE 1 & MODE 3
  ;; CPHA 1 = shif new data outon rising edge
  ;; PUT A BRANCH HERE TO MAKE SWAPPING MODES EASIER?
  
  inc SPI_PORT
  
  dey
  bne spi_loop
  lda SPIIN
  clc
  
  sta PORTA_2   ; show on LEDs just for fun
  
  rts
  

