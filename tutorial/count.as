ca65 V2.18 - Debian 2.19-1
Main file   : count.asm
Current file: count.asm

000000r 1               
000000r 1               	.org $8000
008000  1               
008000  1               reset:
008000  1  A9 FF        	lda #$ff
008002  1  8D 02 60     	sta $6002
008005  1               
008005  1  A9 01        	lda #$01
008007  1  8D 00 60     	sta $6000
00800A  1               
00800A  1               loop0:
00800A  1  2A           	rol
00800B  1  8D 00 60     	sta $6000
00800E  1  2A           	rol
00800F  1  8D 00 60     	sta $6000
008012  1  2A           	rol
008013  1  8D 00 60     	sta $6000
008016  1  2A           	rol
008017  1  8D 00 60     	sta $6000
00801A  1  2A           	rol
00801B  1  8D 00 60     	sta $6000
00801E  1  2A           	rol
00801F  1  8D 00 60     	sta $6000
008022  1  2A           	rol
008023  1  8D 00 60     	sta $6000
008026  1               
008026  1               loop1:
008026  1  69 01        	adc #$01
008028  1  8D 00 60     	sta $6000
00802B  1  4C 26 80     	jmp loop1
00802E  1               
00802E  1               
00802E  1               	.org $fffc
00FFFC  1  00 80        	.word reset
00FFFE  1  00 00        	.word $0000
010000  1               
010000  1               
