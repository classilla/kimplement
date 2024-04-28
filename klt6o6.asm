; kim titler and utilities, converted from handcoded epyx fastload data
; copyright 2002-2024 cameron kaiser, all rights reserved
; floodgap free software license

#include "k6o6.def"

	.word $c800
	* = $c800

	jmp titler
	jmp prhex
	jmp getsa

	; display brag screen, play funky music, have a good time, etc.
	; this also sets up our custom STOP key handler and dec flag-proof
	; IRQ and NMI handlers

titler	ldx #$00	; first setup colour

lup0	lda #$10
	sta $cc00,x
	sta $cd00,x
	sta $ce00,x
	sta $cf00,x
	inx
	bne lup0
	lda #$00	; turn hi-res on
	sta $d020
	sta $d021
	lda #$04
	sta $dd00
	lda #$38
	sta $d018
	lda #$3b
	sta $d011
	jsr $5000	; init music
	sei
	lda #<ttlirq
	sta $0314
	lda #>ttlirq
	sta $0315	; point timer A to our interrupt
	lda #<custop
	sta 808
	lda #>custop
	sta 809		; and point ISTOP to our custom STOP routine
	cli
lup1	jsr $ffe4	; wait for a key
	cmp #$00
	beq lup1
	sei		; install augmented Kernal IRQ with interval timers
	lda #<decirq
	sta $0314
	lda #>decirq
	sta $0315	
	lda #<decnmi	; and augmented NMI
	sta $0316
	lda #>decnmi
	sta $0317
	cli		; but leave STOP where it is
	lda #$07	; return screen to text/$0400
	sta $dd00
	lda #$17
	sta $d018
	lda #$1b
	sta $d011
	lda #$00
	sta $d418
	rts		; and return to BASIC stub to finish emulation init

ttlirq	jsr $5003	; very simple IRQ, just calls the player routine
	jmp $ea31

custop	lda #$ff	; very simple routine, acts as if $91 has no key at all
	rts
decirq	cld		; clear decimal flag before handling IRQ
	; decrement interval timer 16 for NTSC, 20 for PAL
	; because the other timers are in use for RS-232 and serial, we use
	; the timer A IRQ and decrease it by the right number of ticks.
	; we only support the 1024usec one because the others decrease too
	; fast to work with timer A (more than 255 per interval).
	lda kimram+$1707
	sec
	sbc #16
	sbc 678		; "PAL bit" x 4
	sbc 678
	sbc 678
	sbc 678
	sta kimram+$1707
	sta kimram+$1706
	sta kimram+$1705
	sta kimram+$1704; so that programs using this for random numbers work
	; km6o6 handles jiffy clock at 1708

	jmp $ea31
decnmi	cld		; clear decimal flag before handling NMI
	jmp $fe47

	; print a hexadecimal quantity (up to 16 bits)
	; mostly a utility routine for the BASIC stub
prhex	jsr $aefd	; get argument from BASIC
	jsr $ad9e
	jsr $b7f7
	lda $15		; don't display hb if it's zero
	beq hexlb
hexhb	lsr		; display hb
	lsr
	lsr
	lsr
	tax
	lda hextab,x	; first nybble
	jsr $ffd2
	lda $15
	and #$0f
	tax
	lda hextab,x	; second nybble
	jsr $ffd2
hexlb	lda $14		; display lb, in the same fashion
	lsr
	lsr
	lsr
	lsr
	tax
	lda hextab,x
	jsr $ffd2
	lda $14
	and #$0f
	tax
	lda hextab,x
	jmp $ffd2

hextab	.byt $30,$31	; '0123456789abcdef'
	.byt $32,$33,$34
	.byt $35,$36,$37
	.byt $38,$39,$41
	.byt $42,$43,$44
	.byt $45,$46

	; utility routine for quickly getting starting address of a file
getsa	jsr $aefd	; get channel number from BASIC
	jsr $ad9e
	jsr $b7f7
	ldx $14		; chkin
	jsr $ffc6
	jsr $ffe4	; read off first two bytes
	sta $c3		
	jsr $ffe4
	sta $c4
	jmp $ffcc	; and clrchn back to BASIC
