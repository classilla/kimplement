; harness for kim-6o6
; copyright 2002-2024 cameron kaiser, all rights reserved
; floodgap free software license

#include "6o6.def"	
#include "k6o6.def"
#include "kh6o6.def"

	.word harness
	* = harness

	jmp mpeek
	jmp spush
	jmp spull
	jmp stsx
	jmp stxs

        ; these drivers should not change dptr

	; kimplement memory layout emulates a 16K kim ($0000-$3fff).
	; based on the KIM-4 memory map. this means that there is mapped
	; space only from $0000-$3fff. locations $fff8-$ffff are mirrors
	; of $1ff8-$1fff.

	; once we have confirmed valid locations, then based on our
	; virtual RAM location of $4000-$7fff, we just need to AND the high
	; byte with 63, and then OR it with 64, to get the right location.

	; poke .a into location indicated by dptr

#if(0)
mpoke	sta hhold1
	lda dptr+1
	sta hhold0
	tax
	cmp #$18
	bcc mpokeok
	cmp #$40		; unmapped space
	bcs mpokeno
	cmp #$20
	bcs mpokeok		; to support $2xxx memory expansion
mpokeno	lda hhold1
	;jmp mpokdun		; can't write to ROM, even emulated ;-)
	rts			; never changed dptr, needn't restore it
mpokeok	ora #%01000000
	sta dptr+1
	lda hhold1
	ldy #0
	sta (dptr),y
	cpx #$17		; was effective address in i/o range?
	bne mpoknio		; no
	ldx #>kimio		; yes, save a copy to kim i/o mirror
	stx dptr+1		; (would rather handle i/o elsewhere)
	sta (dptr),y
mpoknio	ldx hhold0
	stx dptr+1
mpokdun	rts
#else
mpoke	tax
	lda dptr+1
	cmp #$18		; below ROM
	bcc mpokeok
	cmp #$40		; unmapped space
	bcs mpokdun
	cmp #$20
	bcc mpokdun		; in ROM
mpokeok	sta hhold0
	ora #%01000000
	sta dptr+1
	txa
	ldy #0
	sta (dptr),y
	ldx hhold0 
	cpx #$17		; was effective address in i/o range?
	bne mpoknio		; no
	ldx #>kimio		; yes, save a copy to kim i/o mirror
	stx dptr+1		; (would rather handle i/o elsewhere)
	sta (dptr),y
mpoknio	stx dptr+1
mpokdun	rts
#endif

	; load .a with location indicated by dptr (y should be zeroed)

/* this is now replaced with an inline code section, see kk6o6.def */
mpeek	MPEEK(dptr)
	rts
/* also look at ZMPEEK in kk6o6.def for the optimized zero page fetch */

	; push .a onto stack (must maintain stack pointer itself)
spush	ldx sptr
	sta kimstack,x
	dec sptr
	rts

	; pull .a from stack (must maintain stack pointer itself)
spull	inc sptr
	ldx sptr
	lda kimstack,x
	rts

	; emulate tsx
stsx	ldx sptr
	rts

	; emulate txs
stxs	stx sptr
	rts

