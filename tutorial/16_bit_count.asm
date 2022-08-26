
	.org $8000

reset:
	lda #$ff
	sta $6002
	sta $6003
	lda #$00
	tax
	tay
		

loop:
	txa
	adc #$01
	tax
	bcs high_b

print:
	txa
	sta $6000
	tya
	sta $6001
	jmp loop

high_b:

	iny
	jmp print

	.org $fffc
	.word reset
	.word $0000

