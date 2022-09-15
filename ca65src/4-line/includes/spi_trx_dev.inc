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




spi_transceive:
  
  stz spiin
  sta spiout
  ldy #08
  lda #MOSI

spi_loop:
  
  clc
  asl spiout
  bcs spi_1
  trb SPI_PORT
  jmp spi_2

spi_1:
  
  tsb SPI_PORT

spi_2:
  
  inc SPI_PORT
  bit SPI_PORT
  clc
  bvc spi_3
  sec

spi_3:
  
  rol spiin
  dec SPI_PORT
  dey
  bne spi_loop
  lda spiin
  clc
  ;jsr print_char
  sta PORTA_2

  
  
  rts
  

