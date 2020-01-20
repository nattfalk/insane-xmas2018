
    *** MiniWrapper by Photon ***

********** Symbols **********

	INCLUDE "includes/Blitter-Register-List.i"

********** Macros **********

WAITBLIT:MACRO
	tst.w (a6)			;A1000 blitwait bug fix
.wb\@:	btst #6,DMACONR(a6)
	bne.s .wb\@		;use "bne.s *-4" in incompatible assemblers
	ENDM

Start:	move.l 4.w,a6			;Exec library base address in a6
	sub.l a4,a4
	btst #0,297(a6)			;68000 CPU?
	beq.s .yes68k
	lea .GetVBR(PC),a5		;else fetch vector base address to a4:
	jsr -30(a6)			;enter Supervisor mode

    *--- save view+coppers ---*

.yes68k:lea .GfxLib(PC),a1		;either way return to here and open
	jsr -408(a6)			;graphics library
	tst.l d0			;if not OK,
	beq.s .quit			;exit program.
	move.l d0,a5			;a5=gfxbase

	move.l a5,a6
	move.l 34(a6),-(sp)
	sub.l a1,a1			;blank screen to trigger screen switch
	jsr -222(a6)			;on Amigas with graphics cards

    *--- save int+dma ---*

	lea $dff000,a6
	bsr.s WaitEOF			;wait out the current frame
	move.l $1c(a6),-(sp)		;save intena+intreq
	move.w 2(a6),-(sp)		;and dma
	move.l $6c(a4),-(sp)		;and also the VB int vector for sport.
	bsr.s AllOff			;turn off all interrupts+DMA

    *--- call demo ---*

	movem.l a4-a6,-(sp)
	bsr.w Demo			;call our demo \o/
	movem.l (sp)+,a4-a6

    *--- restore all ---*

	bsr.s WaitEOF			;wait out the demo's last frame
	bsr.s AllOff			;turn off all interrupts+DMA
	move.l (sp)+,$6c(a4)		;restore VB vector
	move.l 38(a5),$80(a6)		;and copper pointers
	move.l 50(a5),$84(a6)
	addq.w #1,d2			;$7fff->$8000 = master enable bit
	or.w d2,(sp)
	move.w (sp)+,$96(a6)		;restore DMA
	or.w d2,(sp)
	move.w (sp)+,$9a(a6)		;restore interrupt mask
	or.w (sp)+,d2
	bsr.s IntReqD2			;restore interrupt requests

	move.l a5,a6
	move.l (sp)+,a1
	jsr -222(a6)			;restore OS screen

    *--- close lib+exit ---*

	move.l a6,a1			;close graphics library
	move.l 4.w,a6
	jsr -414(a6)
.quit:	moveq #0,d0			;clear error return code to OS
	rts				;back to AmigaDOS/Workbench.

.GetVBR:dc.w $4e7a,$c801		;hex for "movec VBR,a4"
	rte				;return from Supervisor mode

.GfxLib:dc.b "graphics.library",0,0

WaitEOF:				;wait for end of frame
	; bsr.w WaitBlitter
	WAITBLIT
	move.w #$138,d0
WaitRaster:				;Wait for scanline d0. Trashes d1.
.l:	move.l 4(a6),d1
	lsr.l #1,d1
	lsr.w #7,d1
	cmp.w d0,d1
	bne.s .l			;wait until it matches (eq)
	rts

AllOff:	move.w #$7fff,d2		;clear all bits
	move.w d2,$96(a6)		;in DMACON,
	move.w d2,$9a(a6)		;INTENA,
IntReqD2:
	move.w d2,$9c(a6)		;and INTREQ
	move.w d2,$9c(a6)		;twice for A4000 compatibility
	rts

; WaitBlitter:				;wait until blitter is finished
; 	tst.w (a6)			;for compatibility with A1000
; .loop:	btst #6,2(a6)
; 	bne.s .loop
; 	rts

SetBpl:				;Generic, poke ptrs into copper list
.bpll:	
	move.l a0,d2
	swap d2
	move.w d2,(a1)			;high word of address
	move.w a0,4(a1)			;low word of address
	addq.w #8,a1			;skip two copper instructions
	add.l d0,a0			;next ptr
	dbf d1,.bpll
	rts

Fade:
	move.w	d7,Fade_count

	move.l	Fade_oldcol(pc),a1
	move.l	Fade_newcol(pc),a2
	move.l	Fade_coppnt(pc),a0
	move.l	Fade_noofcols(pc),d7
	moveq	#0,d6
	move.w	Fade_speed(pc),d6
	subq	#1,d7
.fade_loop:
	move.w	(a2)+,d0
	move.w	d0,d1
	andi.w	#$00f0,d1
	eor.w	d1,d0
	move.b	d0,d2
	ext.w	d2
	lsr.w	#8,d0
	lsr.w	#4,d1

	move.w	(a1)+,d3
	move.w	d3,d4
	andi.w	#$00f0,d4
	eor.w	d4,d3
	move.b	d3,d5
	ext.w	d5
	lsr.w	#8,d3
	lsr.w	#4,d4

	sub.w	d3,d0
	sub.w	d4,d1
	sub.w	d5,d2

	muls.w	Fade_count(pc),d0
	muls.w	Fade_count(pc),d1
	muls.w	Fade_count(pc),d2
	divs.w	d6,d0
	divs.w	d6,d1
	divs.w	d6,d2

	add.w	d3,d0	
	add.w	d4,d1
	add.w	d5,d2

	lsl.w	#8,d0
	lsl.w	#4,d1
	or.w	d1,d0
	or.w	d2,d0

	move.w	d0,2(a0)

	lea	4(a0),a0
	dbf	d7,.fade_loop
	move.w	Fade_count(pc),d7
	rts

	even
Fade_oldcol:	dc.l	0
Fade_newcol:	dc.l	0
Fade_coppnt:	dc.l	0
Fade_noofcols:	dc.l	0
Fade_count:		dc.l	0
Fade_speed:		dc.w	0
Fade_current:	dc.w	0
Fade_velocity:	dc.w	0

	even