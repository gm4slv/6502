
	.org $8000

reset:
	lda #$ff
	sta $6002

	lda #$01
	sta $6000

loop0:
	rol
	sta $6000
	rol
	sta $6000
	rol
	sta $6000
	rol
	sta $6000
	rol
	sta $6000
	rol
	sta $6000
	rol
	sta $6000

loop1:
	adc #$01	
	sta $6000
	jmp loop1


	.org $fffc
	.word reset
	.word $0000

