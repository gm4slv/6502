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
  
  stz spiin
  
  sta spiout
  ldy #08
  
  lda #CS
  tsb SPI_PORT
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
  
  ;pha
  ;lda #SCK
  ;trb SPI_PORT
  ;pla
  dec SPI_PORT
  
  bit SPI_PORT
  clc
  bvc spi_3
  sec

spi_3:
  
  rol spiin
  
  ;pha
  ;lda #SCK
  ;tsb SPI_PORT
  ;pla
  
  inc SPI_PORT
  
  dey
  bne spi_loop
  lda spiin
  clc
  ;jsr print_char
  sta PORTA_2
  
  
  
  
  rts
  

