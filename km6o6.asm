; kim kernel (split between this driver and the BASIC running process)
; this is where the guts of the non-CPU emulation reside
; copyright 2002-2024 cameron kaiser, all rights reserved
; floodgap free software license

#include "6o6.def"	
#include "k6o6.def"

; turn this on for egregiously intrusive diagnostics
; enable keyBoard mode and hold down shift key
/* #define STEPWISE  */
/* */

	.word driver
	* = driver

	jmp cold
	jmp warm

	; soft switches with default values
romscnd	.byt 0		; if 1, use ROM version of scand (else emulator trap)
lscands	.byt 0		; used to signal scands was last to light the leds
keymode	.byt 0		; 0 = keypad, 1 = tty, toggled by shift; set
			; back to keypad on reset, set to tty by rubout
sstmode	.byt 0		; 1 = emulated sst switch is on (basic glue sets it)
sstnext	.byt 0		; 1 = wait one instruction for sst, 0 = nmi now
keymott	.byt 0		; keymode timeout timer. checks on polled frequency.
			; this is actually used as a tick counter by lots of
			; things like keyscan and sprite LED shadow sync.
realser	.byt 0		; use user port for TTY

	; global flags
isvgetc	.byt 255	; waiting for a key in emulated vgetch 0 = YES.

disvec	= $009c
disvecz	= $9c

kimtirq	; ... doesn't exist!
kimtnmi ; push pc and status onto stack
	; we could use 6o6's doirq but we've been doing it this way before
	lda pc+1	; put high byte on first so it comes off last
	jsr kimpush
	lda pc
	jsr kimpush
	lda preg
	jsr kimpush
	lda #$f3
	sta 2040
	lda #0
	sta keymode	; keypad is now back on
	; trigger nmi
	lda kimnmi
	sta pc
	lda kimnmi+1
	sta pc+1
	jmp lup

debuge	lda #0		; test vector
	sta kimreset
	sta kimreset+1
	lda #255
	sta sptr

	; cold start

cold
kimrst	lda kimreset
	sta pc
	lda kimreset+1
	sta pc+1
	; reset LEDs, set LEDs to keypad
	lda #$f3
	sta 2040
	lda #$80
	sta 2041
	jsr osadrst
	jsr upshad
	lda #0
	sta keymode	; keypad is back on
	sta 162		; benchmark hack
	sta keymott	; reset keymode timeout
	lda #$ff
	sta isvgetc	; remember, 0 = WAITING.
	; the safest way to reset the rs-232 buffers is to make start = end
	sei
	lda $029b
	sta $029c
	lda $029d
	sta $029e
	cli

	; warm entry point
warm	lda #$2e
	sta $01		; turn BASIC off to expose vmu
	; do NOT reset keymott here, possibility of endless loop

	; main loop!
lup	; first service i/o and special hardware services
	; non-IRQ interval timers serviced by IRQ routine in klt6o6
	; jiffy clock for time tests to $1708
	lda 162
	sta kimram+$1708

	; handle tick counter
	inc keymott

	; do we need to service the option keys?
	lda #3
	bit keymott
	bne riots	; only every fourth tick

	; is the toggle entry device key (shift key) being pressed?
keykey	lda #1
	clc
	adc keymode
	adc keymode	; in keyBoard mode, to allow shifted chars,
			; we want SHIFT-C= to toggle device
	cmp 653
	bne rstkey
	sta 53281
keylup0	lda 653
	cmp #0
	bne keylup0
	lda #5
	sta 53281
	lda keymode	; yes, flip mode and display new mode
	eor #1
	sta keymode
	ldx #0
	stx 198		; just in case
	ldx #$f3
	cmp #1
	bne *+4
	ldx #$fc
	stx 2040
	
	; is the reset key (commodore key) being pressed?
rstkey	lda 653
	cmp #2
	bne nmikey
	sta 53281
rstlup0	lda 653
	cmp #2
	beq rstlup0
	lda #5
	sta 53281
	lda #254
	jmp tobasic

	; is the ctrl key (nmi/stop) being pressed?
	; (we check sst switch *after* an instruction)
nmikey	lda #4
	clc
	adc keymode
	adc keymode	; just like with shift, need CTRL-C= in keyBoard mode
	cmp 653
	bne riots
	sta 53281
nmilup0	lda 653
	cmp #0
	bne nmilup0
	lda #5
	sta 53281
	jmp kimtnmi

riots
	; RIOT emulation begins here

	; refresh sprite shadow pointers?
	lda #15
	bit keymott
	bne riotsw
	; yes, in two phases, fast refresh and full refresh
	ldx #5
riotsl	lda sshadow,x
	cmp #128
	beq *+5		; skip blanks on fast refresh to mimic real LEDs
	sta 2042,x
	dex
	bpl riotsl
	lda #255
	bit keymott
	bne riotsw
	jsr upshad	; full refresh including blanks

	; if waiting in vgetch, we do NOT continue with emulation until
	; the key is pressed
riotsw	lda isvgetc
	bne osad	; not waiting
	jmp vgetcok	; last character was a null, so we're waiting

	; check $174x

osad	lda kimio+$41	; check padd
	cmp #$7f	; outputs?
	bne isad	; no

	; emulate all outputs of sad 1740 that we need (i.e. the leds)
osado	lda lscands	; did emulated scands light this last time?
	cmp #0
	beq *+5		; no
	jsr osadrst	; yes, so clean leds off
	lda kimio+$42	; check sbd
	sec
	sbc #8		; digits go, l-r, 9, 11, 13 ...
	lsr		; don't care about lowest bit
	cmp #7
	bcs isad	; invalid index
osadok	tax
	lda kimio+$40
	ora #128	; convert to index to sprite images
	sta sshadow,x	; save in shadow registers

isad	; emulate all inputs of sad 1740 that we need
	; race condition here, see bugs
isad20	lda #$ff
	eor keymode	; "jumper on 21-V" means ttymode and makes bit 0 low
	sta kimram+$1740; default state is terminal idle (i.e., bit 7 is high)
			; plus state of jumper

	; always check for inst/del-rubout first due to race condition
	lda 203		; check if a key is being held down
	cmp #0		; inst-del?
	beq isadyes	; yes. we always respond to this regardless of keymode
	lda keymode	; not inst-del. are we using keyBoard?
	cmp #1
	bne isadno	; no. terminal therefore is idle
	; yes. hack for debouncing code - alternate idle and not idle on calls
	lda keymott
	and #1
	beq isadno
	; actually check keys in the buffer, but which buffer?
	lda realser
	beq isadkb
	lda $029b	; are there keys in the Kernal RS-232 receive buffer?
	cmp $029c
	bne isadni	; yes, start != end, set terminal NOT idle
	jmp isadno	; otherwise leave idle
isadkb	lda 198		; are there keys in the keyboard buffer?
	cmp #0
	bne isadni	; keys in the buffer, set terminal NOT idle
	jmp isadno	; otherwise leave idle

	; rubout (run regardless of current mode)
isadyes	lda #1		; enable tty for rubout (only)
	sta keymode	; so that future keys also toggle terminal idle
	lda #$fc
	sta 2040	; and flip sprite to keyBoard
	; don't clear rs-232 buffers here
isadni	ldx #0		; bit 1 clear, so we are tty, bit 7 clear, so not idle
	stx kimram+$1740
isadno

lupdio	; enable extra helpings if SST is not on
	lda #0
	sta ehmode
	lda sstmode
	cmp #1
	beq lupdio0
	lda #$fc	; allow low byte of pc to reach $fb
	sta ehmode
lupdio0	lda pc+1	; check where our pc is
	cmp #$20	; are we above ROM?
	bcs notrap	; yes, it's RAM, don't trap
	cmp #$18	; are we in ROM?
	bcs trapit	; yes, see if we need to trap a ROM access
notrap	jmp lup0	; no, no trap needed, it's in RAM
trapit	; check for traps
	; put most common entry points first for speed
	; up to 127 traps can be defined with this method	
	ldx #0
	stx ehmode	; traps not compatible with extra helpings
	lda pc+1
	and #$1f
	sta pc+1
/* debug
cmp #$1f
bne traplup
lda pc
cmp #$3d
bne traplup
inc $d020
*/
traplup	lda traps+1,x
	cmp #$ff
	bne *+5		; not at the end yet
	jmp lup0	; at the end yet
	cmp pc+1
	beq trapck
traplu0	inx
	inx
	jmp traplup
trapck	lda traps,x
	cmp pc
	bne traplu0
	lda vtraps,x	; call the trap
	sta disvecz
	lda vtraps+1,x
	sta disvecz+1

#ifdef STEPWISE
	lda 653
	cmp #1
	bne nostep
	lda #"*"
	jsr $ffd2
	lda #"T"
	jsr $ffd2
	lda #13
	jsr $ffd2
nostep
#endif

	jmp (disvec)	; the vtrap either returns to lup0, or bombs to basic
lup0	jsr vmu		; finally, run the instruction

#ifdef STEPWISE
	pha
	sta $d020
	lda 653
	cmp #1
	bne nostep2
	lda #$2f
	sta $01
	ldx areg
	lda #0
	jsr $bdcd
	lda #32
	jsr $ffd2
	ldx xreg
	lda #0
	jsr $bdcd
	lda #32
	jsr $ffd2
	ldx yreg
	lda #0
	jsr $bdcd
	lda #32
	jsr $ffd2
	ldx pc
	lda pc+1
	jsr $bdcd
	lda #13
	jsr $ffd2
	lda #$2e
	sta $01
nostep2	pla
#endif

	cmp #R_UDI
	beq udih	; debugger breakpoint detected
	cmp #R_OK
	bne ackphth	; oops, there was some other error

	; check sst to see if an NMI should be triggered now
	lda sstmode	; switch on?
	cmp #1
	bne nminsst	; no
	lda pc+1	; yes, let's see if we need it
	and #%00111111	; lop off top bits
	; ROM does not trip sst mode
	cmp #$20
	bcs nmidsst
	cmp #$18
	bcs nminsst
nmidsst	lda sstnext	; stalling at least one instruction?
	cmp #1
	bne nmisst	; no, time's up
	dec sstnext	; yes, temporary reprieve
nminsst	jmp lup
nmisst	jmp kimtnmi	; bye

udih	; handle soft breakpoint
	; replace with JSR (this might work a little funny in I/O range)
	lda pc
	sta dptr
	lda pc+1
	clc
	adc #$40
	sta dptr+1
	lda #$20
	ldy #0
	sta (dptr),y
	; and trigger NMI
	jmp kimtnmi

ackphth	; error handler
	sta 787
	lda #0
	sta 162
flashy	sta 53280	; the neuralyser
	eor 787
	ldx 162
	cpx #5
	bcc flashy
	lda #0
	sta 53280	; leaving it in 787
	lda 787
tobasic	sta 787		; oh, basic, help me, you're the only one who can
	lda #$2f
	sta $01		; and turn BASIC ROM back on, of course ...
	rts

	; pc-trap listings

traps	.word $1efe	; ak
	.word $1f1f	; scands
	.word $1c4f	; start
	.word $1e5a	; getch
	.word $1ea0	; outch
	.word $1f6a	; getkey
	.word $1f5b	; convd1
	.word $1c2a	; detcps
	.word $1dc8	; goexec
	.word $1f7a	; keyin
	.word $ffff	; end of traps

vtraps	.word vak
	.word vscands
	.word vstart
	.word vgetch
	.word voutch
	.word vgetkey
	.word vconvd1	; do NOT delete, the native scand needs this!!!
	.word vdetcps
	.word vgoexec
	.word vkeyin
	.word $ffff

	; called by voutch and vgetch to print a character in .a
	; (vgetch jumps in through voutcok)
	; also maintains the cursor

	; jump in here for translation (character should be in areg)
vvoutch	lda areg
	cmp #$7f	; character ... is it rubout?
	bne *+7		; no
vvoutde	lda #20		; yes, make it del instead
	jmp voutcok
	cmp #157	; ... is it cursor left?
	beq vvoutde	; yes, translate to del
	cmp #29		; and make cursor right del too just for easyness
	beq vvoutde

/* future
	cmp #$0a	; no ... is it lf?
	bne *+7		; no
	lda #13		; yes, make it cr instead
	jmp voutcok
*/

	; jump in here to avoid lf/del translation
	;
voutchw	cmp #$0d	; no ... is it cr?
	beq voutcok	; yes, pass that through

	cmp #$07	; no ... is it bel?
	bne voutchn	; no
	; yes -- ring bell (assume SID already setup by BASIC)
	lda #16
	sta 54276
	lda #17
	sta 54276
	jmp voutno

voutchn	cmp #$20
	bcc voutno	; do not print other nonprintable characters to the 64
	cmp #126
	bcs voutno	; as long as we are emulating the asr33, no caps either
			; and do not actually print any stray ASCII-1963 ESC
			; or RUBOUT
	; otherwise add hooks here to exclude 128-191 if you want u/l case
voutcok	tay
	lda 211
	beq *+7		; don't do backspace if in position 0 KLUUUUUUUDGE.
	lda #20
	jsr $ffd2	; backspace over cursor
	tya
	jsr $ffd2	; print new character
	lda #164	; and "_" cursor
	jsr $ffd2
/* doesn't appear we need to debounce keyboard on prints
	lda #0
	sta 198
*/
voutno	rts

	; various traps start here

vtbad	; trap not permitted -- entry point not compatible with emulator
	lda #252
	jmp tobasic

vstart	; virtual vstart resets keyboard buffering, which really causes
	; problems for the rubout-as-reset emulation
	lda #0
	sta 198
	jmp lup0	; and continue

vdetcps	; virtual detcps skips forward to -start 1c4f
	lda #$4f
	sta pc
		;lda #$1c
		;sta pc+1
	jmp lup0

vgetch	; virtual getch calls Kernal ffe4 instead
	; note that while control characters aren't printed, they are ACCEPTED
	; by this routine (which is good enough for Tiny BASIC)
	jsr upshad	; ensure LEDs are synced, as we could be waiting
	lda keymode	; tty is enabled?
	cmp #1
	beq vgetcok
	lda #0
	sta areg	; nope
	jmp vgetcdn
	; yup, which TTY?
vgetcok	lda realser
	beq vgetckk
	; TTY is user port
	ldx #2
	jsr $ffc6	; chkin
	jsr $ffe4	; getin
	cmp #0
	beq *+7
	ldx #5
	stx $d020
	sta isvgetc
	sta areg
	jsr $ffcc	; clrchn
	ldx #0
	stx $d020
	; don't handle rubout here, the real getch doesn't either
	lda isvgetc
	bne vgetcdn	; not null, exit routine, do not echo
	; null. null process loop here as KIM actually waits for "start bit."
	; do NOT continue regular loop. instead, short-circuit emulator with
	; service for special keys, but VMU does NOT execute further until
	; a key is pressed.
	jmp lup		; NOT lup0
	; TTY is console
vgetckk	jsr $ffe4
	sta isvgetc
	cmp #0		; null?
	bne vgetcdi	; no
	jmp lup		; yes, same as above, NOT lup0
vgetcdi	;sta areg	; no. ANY character is fair game, except Commodore key
	cmp #20		; inst/del?
	bne *+10	; no
	jsr voutcok	; yes -- print raw character first, then ...
	lda #$7f	; convert inst/del to rubout
	jmp vgetsta
	cmp #133	; f1? (don't use home because it's ctrl-s)
	bne *+12	; no
	lda #13		; yes -- print cr, then ...
	jsr voutcok
	lda #10		; convert f1 to lf
	jmp vgetsta
	cmp #157	; cursor left?
	beq *+6		; yes: convert to del
	cmp #29		; cursor right?
	bne vgetcee	; no
	lda #20		; yes -- print del, then ...
	jsr voutcok
	lda #8		; convert crsr lf to bs
	jmp vgetsta
vgetcee	and #127
	sta areg
	jsr voutchw	; and safe-print character
	jmp vgetcdn
/* ; disabled unless we decide to add this back -- not as long as
   ;  we emulate an ASR33
	lda areg
	tax
	lda toascii,x	; then convert to ascii
*/
vgetsta	sta areg
vgetcdn	lda #$ff
	sta yreg	; see page 22
	; flags not useful, so we don't need to set them
	jsr dorts
	jmp lup0

	; OUTCH! THAT WAS MY HANTCH!
voutch	; virtual outch calls Kernal ffd2 instead
	lda realser
	bne voutchs
	; TTY is console
	jsr vvoutch	; call abstracted voutch, XXX inline it?
voutchx	lda #$ff
	sta yreg	; see page 23
	; flags not useful, so we don't need to set them
	jsr dorts
	jmp lup0
voutchs	; TTY is userport
	ldx #2
	stx $d020
	jsr $ffc9	; chkout
	lda areg
	jsr $ffd2	; chrout
	jsr $ffcc	; clrchn
	ldx #0
	stx $d020
	jmp voutchx	; exit through common epilogue

	; for emulated vscands
vconvd	sty hhold0
	tay
	lda kimram+$1fe7,y
	; update sprites immediately, but keep shadow registers current
	sta 2042,x
	sta sshadow,x
	inx
	ldy hhold0
	rts

vscands	; virtual scands has a more stable led routine
	lda romscnd
	cmp #0		; rom or regular version?
	beq vscanok
	lda #0		; rom version
	sta lscands	; make sure flag is off
	jmp lup0	; and resume
vscanok	ldy #3
	ldx #0
	; this is nearly copied verbatim from the kim rom source
vscand1	lda kimram+$00f8,y
	lsr
	lsr
	lsr
	lsr
	jsr vconvd
	lda kimram+$00f8,y
	and #$0f
	jsr vconvd
	dey
	bne vscand1
	lda #1
	sta lscands	; scands did the dirty work last time
	; ensure padd is set to inputs, like the real routine
	lda #0
	sta kimio+$41
	; and fall through to ...

vak	; virtual ak -- check if a key is pressed
	; unlike getch, this does return if no key is pressed
	lda keymode
	cmp #1
	bne vakok
	lda #$ff	; we're in tty mode, return a=0 after eor #$ff
	sta areg
	jmp vakout
	; for race condition reasons, we'll give them the keyboard buffer
	; since this gets used for debouncing, intermittently return no key
	; but only if a key really *isn't* pressed
vakok	lda 203
	cmp #64
	bne vakchk
	; no key is down, occasionally say no key even if one's in the buffer
	dec vakdo
	lda vakdo
	and #4
	bne vakno
vakchk	ldx #$00	; default, we have keys
	lda 198
	cmp #1
	bcs *+4
vakno	ldx #$ff	; no keys in the keyboard buffer, no keys pressed
	stx areg
vakout	lda #$16	
	sta pc
	lda #$1f
	sta pc+1	; see page 25
	; why come back to $1f16, not $1f18? because the eor #255 there is
	; used to set our zero flag for us, which the caller needs (thus we
	; return $ff to make 0, and 0 to make $ff)
	jmp lup0

vakdo	.byt 00

vconvd1	; eliminates "500 cycle wait" in ROM
	lda #$5e
	sta pc
		;lda #$1f
		;sta pc+1	; see page 25
	jmp lup0

	; convert C64 keyboard to keypad presses
	; (common routine used by vgetkey and vkeyin)
	; cannot detect st or rs

	; vgetkey:
	; 0-f = 0-f (0-f)
	; + = + (12)
	; p = pc (14)
	; g = go (13)
	; r = ad "addRess" (10)
	; t = da "daTa" (11)
	; 15 = no key

	; vkeyin:
	; 0 = no key
	; 0, 1, 2| 3, 4, 5, 6 = $40, $20, $10| $08, $04, $02, $01
	; 7, 8, 9| a, b, c, d = same
	; e, f,ad|da, +,go,pc = same

vgetko	lda keymode	; are we in keypad mode?
	ldx #$15	; default: no key
	ldy #$00
	cmp #0
	beq vgetkok	; yes
	jmp vgetkgo	; no, no key
vgetkok	lda 198		; keys to get?
	cmp #1
	bcs *+3	
	rts		; no, return no keys
	jsr $ffe4	; yes
	ldx #$15	; illegal key
	ldy #$00
	cmp #43		; +
	bne *+7
	ldx #$12
	ldy #$04
	rts
	cmp #71		; g
	bne *+7
	ldx #$13
	ldy #$02
	rts
	cmp #80		; p
	bne *+7
	ldx #$14
	ldy #$01
	rts
	cmp #82		; r
	bne *+7
	ldx #$10
	ldy #$10
	rts
	cmp #84		; t
	bne *+7
	ldx #$11
	ldy #$08
	rts
	; hmm, hope it's 0-f
	cmp #71
	bcs vgetkgo	; too high
	cmp #65
	bcc vgetknu	; number?
	sec
	sbc #55
	tax
	lda vgetkdt,x
	tay
	rts
vgetknu	cmp #58
	bcs vgetkgo	; bad range
	cmp #48
	bcc vgetkgo	; bad range
	sec
	sbc #48
	tax
	lda vgetkdt,x
	tay
vgetkgo	rts

	; lookup table for digits for vkeyin
vgetkdt	.byt $40, $20, $10, $08, $04, $02, $01, $40, $20, $10 ; 0-9
	.byt $08, $04, $02, $01, $40, $20 ; a-f

	; neither routine has useful flags, so we don't need to
	; simulate them as part of the result
	
vgetkey	; virtual getkey converts keys to keypad presses
	jsr vgetko
	stx areg
	jsr dorts
	jmp lup0

vkeyin	; check if any key is being pressed (0=no)
	jsr vgetko
	sty areg
	jsr dorts
	jmp lup0

vgoexec	; virtual goexec just turns all leds off before running code,
	; and allows one instruction before sst nmi (if enabled)
	jsr osadrst
	jsr upshad
	lda #0
	sta 162		; for benchmarking
	lda #1
	sta sstnext
	jmp lup0

	; utility subroutines

osadrst	; subroutine to reset leds. do this to shadows only.
	lda #128
	ldx #0
	stx lscands
osadrsl	sta sshadow,x
	inx
	cpx #6
	bne osadrsl
	rts

upshad	; subroutine to sync shadow LEDs to screen LEDs
	ldx #5
upshadl	lda sshadow,x
	sta 2042,x
	dex
	bpl upshadl
	rts

