	section		main, code_c

	INCLUDE     "includes/PhotonsMiniWrapper1.04!.i"

********** Demo **********				;Demo-specific non-startup code below.

w				=	320					;SnowflakeScreen width, height, depth
h				=	256					;wave amplitudes added + bob height
bpls			=	1					;handy values:
bpl				=	w/16*2				;byte-width of 1 bitplane line
bwid			=	bpls*bpl			;byte-width of 1 pixel line (all bpls)

Snowflakes		=	48

*** P61 ***
usecode			=	$1900BD5E
P61mode			=	1
P61pl			=	usecode&$400000
split4			=	0
splitchans		=	1
visuctrs		=	1
asmonereport	=	0
p61system		=	0
p61exec			=	0
p61fade			=	0
channels		=	4
playflag		=	0
p61bigjtab		=	0
opt020			=	0
p61jump			=	0
C				=	0
clraudxdat		=	0
optjmp			=	1
oscillo			=	0
quietstart		=	0
use1Fx			=	0

	ifeq		P61mode-1
p61cia			=	1
lev6			=	1
noshorts		=	0
dupedec			=	0
suppF01			=	1
	endc

*** P61 ***

Demo:			;a4=VBR, a6=Custom Registers Base addr
	movem.l		d0-a6,-(sp)

*--- init ---*
	move.l		#VBint,$6c(a4)
	move.w		#$c020,$9a(a6)
	move.w		#$87e0,$96(a6)

	move.l		#Copper,$80(a6)

	movem.l		d0-a6,-(sp)
	lea			Module1,a0
	sub.l		a1,a1
	sub.l		a2,a2
	moveq		#0,d0
	jsr			P61_Init
	movem.l		(sp)+,d0-a6

*--- clear SnowflakeScreens ---*
	lea			SnowflakeScreen,a1
	bsr.w		ClearScreen
	lea			SnowflakeScreen2,a1
	bsr.w		ClearScreen
	lea			TextScreen1,a1
	bsr.w		ClearScreen
	lea			TextScreen2,a1
	bsr.w		ClearScreen
	lea			TextScreen3,a1
	bsr.w		ClearScreen
	WAITBLIT

; *--- start copper ---*
	move.l      SnowflakesDrawBuffer(pc),a0
	move.l		#h*bwid,d0
	lea			BplPtrs+2,a1
	moveq		#1-1,d1
	bsr.w		SetBpl

	move.l		TextBackBuffer(pc),a0
	move.l		#h*bwid,d0
	lea			BplPtrs+8+2,a1
	moveq		#1-1,d1
	bsr.w		SetBpl

	lea.l		LogoBottom,a0,
	lea.l		LogoBplPtrs+2,a1
	moveq		#bpl,d0
	moveq		#4-1,d1
	bsr.w		SetBpl

spr_xpos		=	176
spr_ypos		=	150
	lea.l		SprData,a0
	moveq		#4-1,d7
	move.w      #(spr_ypos<<8)+spr_xpos,d0
	move.w		#(spr_ypos+80)<<8,d1
.setSprPos:
	move.w		d0,(a0)			; set y-pos and x-pos
	move.w		d1,2(a0)		; set y-stop
	eor.w		#$80,d1			; set attached bit for next sprite
	lea.l		(80+2)*4(a0),a0	; get next sprite data
	move.w		d0,(a0)
	move.w		d1,2(a0)
	eor.w		#$80,d1			; clear attached bit for next sprite
	lea.l		(80+2)*4(a0),a0
	add.w		#$8,d0
	dbf			d7,.setSprPos

	lea.l		SprData,a0
	lea.l		SprPtrs+2,a1
	move.l		#4*(80+2),d0
	moveq		#8-1,d1
	bsr.w		SetBpl

********************  main loop  ********************
	clr.w		Fade_current
MainLoop:
	move.w		#$12c,d0		;No buffering, so wait until raster
	bsr.w		WaitRaster		;is below the Display Window.

	cmp.w		#128,Fade_current
	bgt.s		.fade_done

	move.l		#FromPal,Fade_oldcol
	move.l		#LogoPal,Fade_newcol
	move.l		#LogoCopCols,Fade_coppnt
	move.l		#16,Fade_noofcols
	move.w		#128,Fade_speed
	move.w		Fade_current(pc),d7
	bsr			Fade

	move.l		#SantaSprPal,Fade_newcol
	move.l		#SprCopCols,Fade_coppnt
	move.w		Fade_current(pc),d7
	bsr			Fade

	addq.w		#1,Fade_current
	bra.s		.skip_effects
.fade_done:

	bsr			DrawSnowFlakes

*--- swap buffers ---*
	movem.l     SnowflakesDrawBuffer(PC),a2-a3
	exg			a2,a3
	movem.l     a2-a3,SnowflakesDrawBuffer	;draw into a2, show a3

	move.l		a3,a0
	moveq		#bpl,d0
	lea			BplPtrs+2,a1
	moveq		#1-1,d1
	bsr.w		SetBpl

	btst		#2,$dff016
	beq.s		.skip_scroller

	bsr			Scroller

.skip_scroller:
	bsr			ScrollerCopyToBackbuffer

; *--- swap buffers ---*
	; WAITBLIT
	movem.l     TextBackBuffer(PC),a2-a3
	exg			a2,a3
	movem.l		a2-a3,TextBackBuffer	;draw into a2, show a3

	move.l		a3,a0
	moveq		#bpl,d0
	lea			BplPtrs+8+2,a1
	moveq		#1-1,d1
	bsr.w		SetBpl

.skip_effects:
*--- main loop end ---*
	btst		#6,$bfe001		;Left mouse button not pressed?
	bne.w		MainLoop		;then loop

*--- exit ---*
	movem.l		d0-a6,-(sp)
	jsr			P61_End
	movem.l		(sp)+,d0-a6

	movem.l		(sp)+,d0-a6
	rts

ScrollCounter:		dc.w		0
DoScroll:			dc.w		0

********** Routines **********
ClearScreen:	;a1=SnowflakeScreen destination address to clear
	WAITBLIT
	clr.w		$66(a6)			;destination modulo
	move.l		#$01000000,$40(a6)	;set operation type in BLTCON0/1
	move.l		a1,$54(a6)		;destination address
	move.w		#h*64+bpl/2,$58(a6)	;blitter operation size
	rts

VBint:			;Blank template VERTB interrupt
	movem.l		d0-d2/a0/a6,-(sp)	;Save used registers
	lea			$dff000,a6
	btst		#5,$1f(a6)		;check if it's our vertb int.
	beq			.notvb
*--- do stuff here ---*

	move.w		FrameCounter(pc),d0
	and.w		#3,d0
	bne.s		.no_move
	move.b		#1,DoScroll
.no_move:
	addq.w		#1,FrameCounter

.vbint_done:
	moveq		#$20,d0			;poll irq bit
	move.w		d0,$9c(a6)
	move.w		d0,$9c(a6)
.notvb:                
	movem.l     (sp)+,d0-d2/a0/a6	;restore
	rte

*****************************************************************
**
** Snowflakes
**
*****************************************************************
DrawSnowFlakes:
	lea.l		SnowflakePositions(pc),a0
	lea.l		Sin(pc),a1
	move.l      SnowflakesDrawBuffer(pc),a2

	lea.l		-Snowflakes*2(a2),a4
	moveq		#Snowflakes-1,d7
.clear_loop_outer:
	move.w		(a4)+,d0
	moveq		#8-1,d6
.clear_loop_inner:
	clr.b		(a2,d0.w)
	clr.b		1(a2,d0.w)
	add.w		#bwid,d0
	dbf			d6,.clear_loop_inner
	dbf			d7,.clear_loop_outer

	lea.l		-Snowflakes*2(a2),a4
	moveq		#Snowflakes-1,d7
.render_loop_outer:
	movem.w		(a0),d0-d5		; x, y, sincounter, sinscale,vertical speed, snowflake_idx
	asr.w		#3,d1

	cmp.w		#0,d1
	bmi			.skip_render
	cmp.w		#255-8,d1
	ble.s		.do_render
	sub.w		#255*8,2(a0)
	bra.s		.skip_render
.do_render:
	and.w		#2047,d2
	move.w		(a1,d2.w),d2
	asr.w		#3,d2

	and.w		#2047,d3
	muls		(a1,d3.w),d2
	asr.w		#8,d2

	add.w		d2,d0

	move.w		d0,d2
	lsr.w		#3,d0			; byte aligned
	and.w		#7,d2			; 

	mulu		#bwid,d1
	add.w		d0,d1
	move.w		d1,(a4)+

	eor.b		#7,d2
	ext.w		d2

	lea.l		SnowflakesData,a3
	lea.l		(a3,d5.w),a3

	moveq		#8-1,d6
.render_flake:
	move.b		(a3)+,d4
	and.w		#$ff,d4
	lsl.w		d2,d4
	or.b		d4,1(a2,d1.w)
	lsr.w		#8,d4
	or.b		d4,(a2,d1.w)
	add.w		#bwid,d1

	dbf			d6,.render_flake

	add.w		#12,4(a0)
	add.w		#46,6(a0)

.skip_render:	
	move.w		8(a0),d0
	add.w		d0,2(a0)

	lea.l		12(a0),a0
	dbf			d7,.render_loop_outer
	rts

SnowflakePositions:
	dc.w		75,-345,102,942,4,48
	dc.w		204,-910,594,1392,4,40
	dc.w		174,-177,1302,1456,2,32
	dc.w		145,-511,1966,1022,6,0
	dc.w		67,-1882,1830,958,6,24
	dc.w		186,-292,548,94,3,16
	dc.w		173,-857,1556,490,1,48
	dc.w		152,-416,1298,42,4,48
	dc.w		10,-731,1412,1058,4,32
	dc.w		14,-556,140,1966,2,24
	dc.w		8,-1642,1450,1680,1,32
	dc.w		152,-989,1120,552,2,32
	dc.w		278,-1580,1390,150,1,48
	dc.w		143,-1677,1246,1840,4,8
	dc.w		238,-1869,780,1280,1,32
	dc.w		95,-817,652,612,2,48
	dc.w		60,-675,1470,1976,4,48
	dc.w		140,-532,1002,38,5,8
	dc.w		293,-105,1470,210,4,0
	dc.w		260,-1829,1508,1032,1,48
	dc.w		93,-279,1006,1862,7,24
	dc.w		112,-789,2024,1644,7,16
	dc.w		81,-1039,1322,1342,4,40
	dc.w		219,-488,982,268,5,0
	dc.w		280,-1644,196,484,4,0
	dc.w		49,-664,1288,1484,5,32
	dc.w		144,-943,1568,1922,5,48
	dc.w		85,-1714,108,774,6,0
	dc.w		137,-1640,1336,36,6,8
	dc.w		160,-1723,412,852,7,40
	dc.w		142,-1806,340,1752,5,8
	dc.w		218,-974,1664,2000,2,48
	dc.w		289,-458,190,1000,7,24
	dc.w		14,-937,694,170,6,8
	dc.w		150,-1795,1812,714,2,24
	dc.w		146,-1949,1122,2022,4,24
	dc.w		252,-1214,1014,1706,5,16
	dc.w		67,-1102,4,1516,1,0
	dc.w		63,-1990,584,1434,3,24
	dc.w		138,-1281,646,1874,3,24
	dc.w		107,-1303,638,596,4,8
	dc.w		115,-72,598,1106,5,24
	dc.w		9,-1656,1788,12,7,16
	dc.w		81,-532,110,1782,2,8
	dc.w		78,-477,1328,202,4,0
	dc.w		78,-185,60,1944,4,16
	dc.w		14,-188,1946,1746,3,0
	dc.w		221,-722,738,1678,5,8
	dc.w		178,-1157,1000,2000,5,32
	dc.w		153,-1092,406,256,1,40
	dc.w		156,-1499,854,372,3,40
	dc.w		137,-1926,1414,1162,7,48
	dc.w		123,-1233,744,1950,2,24
	dc.w		252,-1190,148,904,4,0
	dc.w		192,-1510,496,804,4,0
	dc.w		39,-216,1748,424,3,0
	dc.w		210,-939,702,1240,3,32
	dc.w		160,-2024,914,1050,5,8
	dc.w		88,-942,646,1398,3,32
	dc.w		206,-1921,1518,620,4,0
	dc.w		159,-1952,1222,1348,4,0
	dc.w		44,-1670,86,516,2,32
	dc.w		59,-1592,66,888,7,24
	dc.w		205,-1818,1376,1990,1,48

*****************************************************************
**
** Scroller
**
*****************************************************************
Scroller:
	tst.b		DoScroll
	beq.s		.skip_scroller
	clr.b		DoScroll

	move.w		ScrollCounter(pc),d0
	sub.w		#12,d0
	bne.s		.skip_print
	bsr			PrintText
	clr.w		ScrollCounter
.skip_print:
	addq.w		#1,ScrollCounter

	WAITBLIT
	move.l		#$09f00000,BLTCON0(a6)
	move.l		#-1,BLTAFWM(a6)
	move.w		#0,BLTAMOD(a6)
	move.w		#0,BLTDMOD(a6)
	move.l		#TextScreen1,d0
	move.l		d0,BLTDPTH(a6)
	add.l		#40,d0
	move.l		d0,BLTAPTH(a6)
	move.w      #(184+8-1)*64+20,BLTSIZE(a6)

.skip_scroller:
	rts

ScrollerCopyToBackbuffer:
	WAITBLIT
	move.l		#$09f00000,BLTCON0(a6)
	move.l		#TextScreen1,BLTAPTH(a6)
	move.l      TextBackBuffer(pc),BLTDPTH(a6)
	move.l		#-1,BLTAFWM(a6)
	move.w		#0,BLTAMOD(a6)
	move.w		#0,BLTDMOD(a6)
	move.w      #(184+8)*64+20,BLTSIZE(a6)
	rts

PrintText:
	; WAITBLIT
	move.l		TextPtr(pc),a0	; text
	lea.l		Font,a1			; font
	lea.l		TextScreen1,a2
	moveq		#0,d0			; x
	move.w		#(184-1)*40,d1	; y
	moveq		#0,d2			; charpos

	moveq		#40-1,d7
.chr_loop:

	move.b		(a0)+,d3		; current char

	sub.b		#' ',d3
	ext.w		d3
	lsl.w		#3,d3

	move.w		d0,d4
	add.w		d1,d4
	moveq		#8-1,d6
.draw_loop:
	move.b		(a1,d3.w),(a2,d4.w)
	addq.w		#1,d3
	add.w		#bwid,d4
	dbf			d6,.draw_loop

	addq.w		#1,d0			; next screen pos

	dbf			d7,.chr_loop

	move.b		(a0)+,d0
	beq.s		.reset_text
	add.l		#40,TextPtr
	bra.s		.quit
.reset_text:
	move.l		#ScrollText,TextPtr
.quit:
	rts

	include		"includes/P6112-Play.i"

	even
********** Fastmem Data *********
FrameCounter:			dc.w	0

*--- double buffering base ptrs ---*
SnowflakesDrawBuffer:	dc.l	SnowflakeScreen2
SnowflakesViewBuffer:	dc.l	SnowflakeScreen

TextBackBuffer:			dc.l	TextScreen2
TextViewBuffer:			dc.l	TextScreen3

TextPtr:				dc.l	ScrollText

Sin:
	INCBIN		"data/Sine1024w.bin"	;amplitude 512 for precision
SinEnd:
Cos				=	Sin+((SinEnd-Sin)/4)&$fffffffe	;quarter turn offset

FromPal:	
	dc.w        $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w        $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

	include		"gfx/snowflakes.i"
	include		"gfx/logo.pal"
	include		"gfx/sprite.pal"

	include		"src/scrolltext.i"

*******************************************************************************
	SECTION		ChipData,DATA_C	;declared data that must be in chipmem
*******************************************************************************
Copper:
	dc.w		$1fc,0		;Slow fetch mode, remove if AGA demo.
	dc.w		$8e,$2c81	;238h display window top, left
	dc.w		$90,$2cc1	;and bottom, right.
	dc.w		$92,$38		;Standard bitplane dma fetch start
	dc.w		$94,$d0		;and stop for standard screen.

	dc.w		$108,0		; bwid-bpl		;modulos
	dc.w		$10a,0		; bwid-bpl

	dc.w		$102,0		;Scroll register (and playfield pri)
	dc.w		$104,$0024
	dc.w		$106,$0c00

BplPtrs:
	dc.w		$e0,0
	dc.w		$e2,0
	dc.w		$e4,0
	dc.w		$e6,0
	dc.w		$e8,0
	dc.w		$ea,0
	dc.w		$ec,0
	dc.w		$ee,0
	dc.w		$100,2*$1000+$200	;enable bitplanes

SprPtrs:
	dc.w		$0120,0,$0122,0
	dc.w		$0124,0,$0126,0
	dc.w		$0128,0,$012a,0
	dc.w		$012c,0,$012e,0
	dc.w		$0130,0,$0132,0
	dc.w		$0134,0,$0136,0
	dc.w		$0138,0,$013a,0
	dc.w		$013c,0,$013e,0

SprCopCols:
	dc.w        $01a0,$0000,$01a2,$0000,$01a4,$0000,$01a6,$0000
	dc.w        $01a8,$0000,$01aa,$0000,$01ac,$0000,$01ae,$0000
	dc.w        $01b0,$0000,$01b2,$0000,$01b4,$0000,$01b6,$0000
	dc.w        $01b8,$0000,$01ba,$0000,$01bc,$0000,$01be,$0000

Palette:			
	dc.w        $182,$0023,$184,$0023,$186,$0023
	dc.w		$3001,$fffe
	dc.w        $182,$0234,$184,$0244,$186,$0244
	dc.w		$3101,$fffe
	dc.w        $182,$0455,$184,$0466,$186,$0466
	dc.w		$3201,$fffe
	dc.w        $182,$0667,$184,$0688,$186,$0688
	dc.w		$3301,$fffe
	dc.w        $182,$0888,$184,$09aa,$186,$09aa
	dc.w		$3401,$fffe
	dc.w        $182,$0aaa,$184,$0ccc,$186,$0ccc
	dc.w		$3501,$fffe
	dc.w        $182,$0ccc,$184,$0fff,$186,$0fff

	dc.w		$d801,$fffe
	dc.w        $182,$0ccc,$184,$0fff,$186,$0fff
	dc.w		$d901,$fffe
	dc.w        $182,$0aaa,$184,$0ccc,$186,$0ccc
	dc.w		$da01,$fffe
	dc.w        $182,$0888,$184,$09aa,$186,$09aa
	dc.w		$db01,$fffe
	dc.w        $182,$0667,$184,$0688,$186,$0688
	dc.w		$dc01,$fffe
	dc.w        $182,$0455,$184,$0466,$186,$0466
	dc.w		$dd01,$fffe
	dc.w        $182,$0234,$184,$0244,$186,$0244
	dc.w		$de01,$fffe
	dc.w        $182,$0023,$184,$0023,$186,$0023

	dc.w		$e601,$fffe
LogoBplPtrs:
	dc.w		$e0,0,$e2,0
	dc.w		$e4,0,$e6,0
	dc.w		$e8,0,$ea,0
	dc.w		$ec,0,$ee,0
	dc.w		$100,$4200	;enable bitplanes
	dc.w		$108,bwid*3	;modulos
	dc.w		$10a,bwid*3

LogoCopCols:
	dc.w        $0180,$0000,$0182,$0000,$0184,$0000,$0186,$0000
	dc.w        $0188,$0000,$018a,$0000,$018c,$0000,$018e,$0000
	dc.w        $0190,$0000,$0192,$0000,$0194,$0000,$0196,$0000
	dc.w        $0198,$0000,$019a,$0000,$019c,$0000,$019e,$0000

	dc.w        $01a0,$0000,$01a2,$0000,$01a4,$0000,$01a6,$0000
	dc.w        $01a8,$0000,$01aa,$0000,$01ac,$0000,$01ae,$0000
	dc.w        $01b0,$0000,$01b2,$0000,$01b4,$0000,$01b6,$0000
	dc.w        $01b8,$0000,$01ba,$0000,$01bc,$0000,$01be,$0000

	dc.w		$ffdf,$fffe	;allow VPOS>$ff

	dc.w		$ffff,$fffe	;magic value to end copperlist
CopperE:

		include     "gfx/xmas_sprite16col_64x80.spr"

*--- external files ---*
Font:                  incbin      "gfx/vedderfont5.8x520.1.raw"
LogoBottom:            incbin      "gfx/xmas16col_70x320.raw"
Module1:               incbin      "music/P61.chip band aid 2016"

*******************************************************************************
	SECTION		ChipBuffers,BSS_C	;BSS doesn't count toward exe size
*******************************************************************************
*--- data for buffer 1 ---*
					ds.w	Snowflakes
SnowflakeScreen:	ds.b	h*bwid			;Define storage for SnowflakeScreen

*--- data for buffer 2 ---*
					ds.w	Snowflakes
SnowflakeScreen2:	ds.b	h*bwid			;two buffers

TextScreen1:		ds.b	h*bwid
TextScreen2:		ds.b	h*bwid
TextScreen3:		ds.b	h*bwid

	END
