; ==============================================================================
; ------------------------------------------------------------------------------
; Macros section
; ------------------------------------------------------------------------------
		include "Macro.asm"				; include built-in constant and macros
		include "LANG.ASM"				; include Z80 language macros
		opt l.						; local label is .
		opt w-						; disable warnings
; ==============================================================================
; ------------------------------------------------------------------------------
; Macro for sending a VDP command
; ------------------------------------------------------------------------------

vdpComm		macro ins,addr,type,rwd,end,end2
	if narg=5
		\ins #(((\type&\rwd)&3)<<30)|(((\addr)&$3FFF)<<16)|(((\type&\rwd)&$FC)<<2)|(((\addr)&$C000)>>14), \end

	elseif narg=6
		\ins #(((((\type&\rwd)&3)<<30)|(((\addr)&$3FFF)<<16)|(((\type&\rwd)&$FC)<<2)|(((\addr)&$C000)>>14))\end, \end2

	else
		\ins (((\type&\rwd)&3)<<30)|(((\addr)&$3FFF)<<16)|(((\type&\rwd)&$FC)<<2)|(((\addr)&$C000)>>14)
	endif
    endm

; values for the type argument
VRAM =  %100001
CRAM =  %101011
VSRAM = %100101

; values for the rwd argument
READ =  %001100
WRITE = %000111
DMA =   %100111
; ==============================================================================
; ------------------------------------------------------------------------------
; Macro for starting a DMA
; ------------------------------------------------------------------------------

vdpDMA		macro source,dest,length,type
		move.l	#(($9400|((((length)>>1)&$FF00)>>8))<<16)|($9300|(((length)>>1)&$FF)),4(a6)
		move.l	#(($9600|((((source)>>1)&$FF00)>>8))<<16)|($9500|(((source)>>1)&$FF)),4(a6)
		move.w	#$9700|(((((source)>>1)&$FF0000)>>16)&$7F),4(a6)
	vdpComm	move.l,\dest,\type,DMA,4(a6)
    endm
; ==============================================================================
; ------------------------------------------------------------------------------
; Main code for MDDC screen
; ------------------------------------------------------------------------------
	org 0							; make sure the z80 stuff builds correctly
	obj MDDC_Start

	; load Z80 driver
		move.w	#$0100,$A11100				; request Z80 stop
		move.w	#$0100,$A11200				; Z80 reset off

		lea	SoundDriver.w,a0			; load sound driver address into a0
		lea	$A00000,a1				; load Z80 RAM address into a1
		move.w	#SoundDriver_Sz-1,d0			; set sound driver size to d0

.z80
		btst	#$00,$A11100				; check if Z80 has stopped
		bne.s	.z80					; if not, wait more

.loadz80
		move.b	(a0)+,(a1)+				; copy 1 byte at a time.. yay!
		dbf	d0,.loadz80				; load every byte
		move.w	#$0000,$A11200				; request Z80 reset


	; initialize other stuff
		lea	$C00000,a6				; load VDP data port to a6
	vdpDMA	MDDC_Main_Art, $80*32, MDDC_Main_Art_End-MDDC_Main_Art, VRAM

		move.w	#$0000,$A11100				; enable Z80
		move.w	#$0100,$A11200				; Z80 reset off

		lea	MDDC_HintCode.w,a0			; load h-int code destination to a0
		lea	MDDC_Hint(pc),a1			; load h-int code source to a1

	rept $10/4
		move.l	(a1)+,(a0)+				; copy h-int code
	endr

		lea	MDDC_ScrollTable2(pc),a0		; load target to a0
		lea	MDDC_ScrollData(pc),a1			; load scroll data array to a1

.next
		moveq	#0,d0
		move.b	(a1)+,d0				; load length to d0
		move.b	(a1)+,d1				; load fill byte to d1

.fill
		move.b	d1,(a0)+				; fill with byte
		dbf	d0,.fill				; loop for all bytes
		tst.w	(a1)					; check if end token was found
		bne.s	.next					; if not, do moar

		move.l	#MDDC_Vint_Animation,MDDC_VintAddr.w	; load vertical interrupt address
		move.w	#$8174,4(a6)				; enable display

MDDC_68kLoop:
		stop	#$2300					; stop CPU for a frame
MDDC_Exit =	*+1
		moveq	#0,d7					; check if exiting was requested
		beq.s	MDDC_68kLoop				; if not, loop
		move	#$2700,sr
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Array for horizontal scrolling stuff
; ------------------------------------------------------------------------------

MDDC_ScrollTable:
		dc.w 8, 8, 8, 9, 9, 9, 9,$A,$A,$A,$A,$A, 9, 9, 9, 9; $10
		dc.w 8, 8, 8, 7, 7, 7, 7, 6, 6, 6, 6, 6, 7, 7, 7, 7; $20

	rsset *
MDDC_Scale_Data:	rs.w 224				; scale mappings data pointer
MDDC_ScrollTable2:	rs.b $100				; scroll table data

MDDC_ScrollData:
		dc.b $18-1, 0, $1C-1, 1, $30-1, 2, $1C-1, 1
		dc.b $18-1, 0, $1C-1,-1, $30-1,-2, $1C-1,-1
		dc.w 0
; ==============================================================================
; ------------------------------------------------------------------------------
; Horizontal interrupts code
; ------------------------------------------------------------------------------

MDDC_Hint:
		move	sr,-(sp)				; save sr into stack
		move.w	MDDC_Scale_Data,(a6)			; load the next scale data to VDP
		addq.w	#2,MDDC_HintCode+6.w			; go to next scale address
		move	(sp)+,sr				; load sr from stack
		rte
; ==============================================================================
; ------------------------------------------------------------------------------
; Various file includes
; ------------------------------------------------------------------------------

MDDC_Hint_End:

MDDC_Main_Art:		incbin "Data/Background Art.unc"	; background art tile data
			incbin "Data/Animation Art.unc"		; animation art tile data
MDDC_Main_Art_End:
MDDC_Logo_Art:		incbin "Data/Logo Art.unc"		; logo art tile data
			incbin "Data/Discord Art.unc"		; discord link tile data
MDDC_Logo_Art_End:
	even
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine to queue a sound
; ------------------------------------------------------------------------------

MDDC_QueueSound:
		move.w	#$0100,$A11100				; request Z80 stop

.z80
		btst	#$00,$A11100				; check if Z80 has stopped
		bne.s	.z80					; if not, wait more
		move.b	d0,$A00000+MDDC_Queue			; send to sound queue
		move.w	#$0000,$A11100				; enable Z80
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine to dump mappings into VRAM
; ------------------------------------------------------------------------------

MDDC_WriteMap:
		move.l	#$800000,d4				; load row size to d4

.row
		move.l	d0,4(a6)				; run VDP command
		move.w	d1,d3					; load column size to d3

.column
		move.w	(a1)+,(a6)				; copy 1 tile
		dbf	d3,.column				; run for all columns

		add.l	d4,d0					; go to next row
		dbf	d2,.row					; run for all rows
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Some variables that are going to overwrite this first part of the code
; ------------------------------------------------------------------------------

	rsset *							; this is how you save on RAM, derp!
MDDC_LogoScrollDelay		rs.w 1				; counter for logo scrolling

MDDC_LightLeft			rs.l 1				; script address for the left lightning
MDDC_DelayLeft			rs.w 1				; delay timer for the left lightning
MDDC_OffsLeft			rs.b 1				; the offset for the left lightning
MDDC_NumLeft			rs.b 1				; the number of iterations for the left lightning

MDDC_LightRight			rs.l 1				; script address for the right lightning
MDDC_DelayRight			rs.w 1				; delay timer for the right lightning
MDDC_OffsRight			rs.b 1				; the offset for the right lightning
MDDC_NumRight			rs.b 1				; the number of iterations for the right lightning
; ==============================================================================
; ------------------------------------------------------------------------------
; Vertical interrupt routine to handle initial animation and cool background
; ------------------------------------------------------------------------------

MDDC_Vint_Animation:
		jsr	MDDC_Ani_Ctrl(pc)			; handle animation and controller input
		beq.s	.rte					; branch if no anim change
		move.l	#.aniy,MDDC_VintAddr.w			; run the next animation code
		moveq	#1,d0
		jsr	MDDC_QueueSound(pc)			; queue reveal sound effect
		rte
; ------------------------------------------------------------------------------

.aniy
		jsr	MDDC_Ani_Ctrl(pc)			; handle animation and controller input
		beq.s	.rte					; branch if no anim change
		move.l	#.ani2,MDDC_VintAddr.w			; run the next animation code

		lea	$FFFF0000,a1				; mappings stored at start of RAM
	vdpComm	move.l,$0000,VRAM,WRITE,d0			; VRAM WRITE $0000
		moveq	#42-1,d1				; 42 columns
		moveq	#29-1,d2				; 28 lines
		jsr	MDDC_WriteMap(pc)			; write to VRAM
		rte
; ------------------------------------------------------------------------------

.ani2
		jsr	MDDC_Ani_Ctrl(pc)			; handle animation and controller input
		beq.s	.rte					; branch if no anim change
		move.l	#.ani3,MDDC_VintAddr.w			; run the next animation code
	vdpDMA	MDDC_Logo_Art, $2A8*32, MDDC_Logo_Art_End-MDDC_Logo_Art, VRAM
		move.w	#$8A00,4(a6)				; interrupt every line

.rte
		rte
; ------------------------------------------------------------------------------

.ani3
		jsr	MDDC_Ani_Ctrl_Scrl(pc)			; handle animation and controller input and scroll
		beq.s	.rte					; branch if no anim change
		move.l	#.anix,MDDC_VintAddr.w			; run the next animation code
		move.w	#280,MDDC_LogoScrollDelay.w		; set logo delay

		move.l	#MDDC_ScriptNull,MDDC_LightRight.w	; load lightning scripts
		move.l	#MDDC_ScriptNull,MDDC_LightLeft.w	;
		clr.l	MDDC_DelayLeft.w			;
		clr.l	MDDC_DelayRight.w			;

	vdpDMA	$FFFF09A0, $E000, $880, VRAM			; DMA mappings into VRAM
		move.w	#$8014,4(a6)				; h-int enable
		move.w	#$8F00,4(a6)				; autoincrement 0
	vdpComm	move.l,$0000,VSRAM,WRITE,4(a6)			; VSRAM write $0000
		rte
; ------------------------------------------------------------------------------

.anix
		jsr	.lightning(pc)				; handle lightning and other stuff
		beq.s	.scroll					; branch if no anim change
		move.l	#.ani4,MDDC_VintAddr.w			; run the next animation code

		moveq	#2,d0
		jsr	MDDC_QueueSound(pc)			; queue logo sound effect
		bra.s	.scroll
; ------------------------------------------------------------------------------

.ani4
		jsr	.lightning(pc)				; handle lightning and other stuff
		beq.s	.scroll					; branch if no anim change
		addq.b	#1,MDDC_BrightBG.w			; go to next entry
		move.l	#.ani5,MDDC_VintAddr.w			; run the next animation code

.scroll
		jsr	MDDC_LightPalette(pc)			; handle lightning palette
		jsr	MDDC_LogoScroll(pc)			; run logo scroll
		rte
; ------------------------------------------------------------------------------

.ani5
		jsr	MDDC_LogoScroll2(pc)			; run logo scroll
		jsr	.lightning(pc)				; handle lightning and other stuff
		beq.s	.rte2					; branch if no anim change
		addq.b	#1,MDDC_BrightBG.w			; go to next entry

		cmp.b	#$C,MDDC_BrightBG.w			; check if this is the max brightness
		bls.s	.rte2					; if no, continue
		move.l	#MDDC_Vint_Logo,MDDC_VintAddr.w		; run the next animation code
		moveq	#5,d0
		jsr	MDDC_QueueSound(pc)			; queue cycle sound effect
		rte

.rte2
		jsr	MDDC_LightPalette(pc)			; handle lightning palette
		rte
; ------------------------------------------------------------------------------

.lightning
		jsr	MDDC_Ani_Ctrl(pc)			; handle animation and controller input
		move	sr,-(sp)				; store sr
		lea	MDDC_ScriptNull(pc),a4			; load null script to a4

		lea	MDDC_LightLeft.w,a2			; load lightninig script to a2
		lea	MDDC_LightDelayLeft(pc),a0		; load script loop to a0
		lea	MDDC_ScriptLightLeft(pc),a1		; load left script main address to a1
		bsr.w	MDDC_LightRestart			; prepare lightning scripts

		jsr	MDDC_Vint_Script(pc)			; run left lightning script
		beq.s	.nores					; branch if no end
		move.l	a4,MDDC_LightLeft.w			; reset lightning script

.nores
		lea	MDDC_LightRight.w,a2			; load lightninig script to a2
		lea	MDDC_LightDelayRight(pc),a0		; load script loop to a0
		lea	MDDC_ScriptLightRight(pc),a1		; load right script main address to a1
		bsr.s	MDDC_LightRestart			; prepare lightning scripts

		jsr	MDDC_Vint_Script(pc)			; run right lightning script
		beq.s	.nores2					; branch if no end
		move.l	a4,MDDC_LightRight.w			; reset lightning script
; ------------------------------------------------------------------------------

.nores2
MDDC_ShakeLen =	*+1
	; handle shaking
		moveq	#0,d0					; check if screen shaking is active
		beq.s	.noshake				; if not, skip
		subq.b	#1,MDDC_ShakeLen.w			; decrease shake counter

		moveq	#$3F,d0					; prepare mask to d0
		and.b	#0,d0					; AND with shake data
		addq.b	#1,*-1.w				; increase shake offset

		lea	MDDC_ShakeArray(pc),a0			; load shake array to a0
		move.b	(a0,d0.w),d0				; load final offset to d0

.noshake
	vdpComm	move.l,$0002,VSRAM,WRITE,4(a6)			; VSRAM WRITE 2
		move.w	d0,(a6)					; save BG and FG offset
; ------------------------------------------------------------------------------

	; handle background scrolling
		move.w	#$8F04,4(a6)				; autoincrement 4
		moveq	#0,d0					; load scroll table offset to d0
		addq.b	#2,*-1.w				; increase table offset
		lea	MDDC_ScrollTable(pc),a0			; load scrolling table to a0

		move.w	#0,d1					; load scroll table offset to d1
		addq.b	#1,*-1.w				; increase table offset
		lea	MDDC_ScrollTable2(pc),a1		; load scrolling table to a1

		moveq	#112-1,d2				; load loop count to d2
		move.l	#$70020003,4(a6)			; VRAM WRITE $F002

.scrollz
		move.b	(a1,d1.w),d3				; write BG position to VDP
		ext.w	d3					; extend to word
		and.w	#$3E,d0					; keep in range
		sub.w	(a0,d0.w),d3				; add secondary table to d3

		move.w	d3,(a6)					; write BG position to VDP
		addq.w	#2,d0					; go to next table entry
		addq.b	#1,d1					;
		dbf	d2,.scrollz				; loop
		move.w	#$8F02,4(a6)				; autoincrement 2

		move	(sp)+,sr				; load into ccr
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine to handle lightning script restarts
; ------------------------------------------------------------------------------

MDDC_LightRestart:
		cmp.l	(a2),a4					; check if running null script atm
		bne.s	.rts					; if not, skip
		move.l	a1,(a2)					; save new script pos

		moveq	#7,d0					; prepare mask to d0
		and.b	7(a2),d0				; AND script num with d0
		addq.b	#1,7(a2)				; increase num

		move.b	(a0,d0.w),d0				; load script delay value
		move.w	d0,4(a2)				; save into script
		clr.b	6(a2)					; clear offset

.rts
		rts
; ------------------------------------------------------------------------------

MDDC_LightDelayLeft:	dc.b 20, 40, 40, 40, 20, 60, 40, 60	; left lightning delay values
MDDC_LightDelayRight:	dc.b 40, 20, 60, 40, 40, 40, 60, 40	; right lightning delay values
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine to handle lightning palette stuff
; ------------------------------------------------------------------------------

MDDC_LightPalette:
		cmp.b	#2,MDDC_OffsLeft.w			; check if offset is 2
		beq.w	.offs2					; if yes, branch
		cmp.b	#2,MDDC_OffsRight.w			; check if offset is 2
		beq.s	.offs2					; if yes, branch

		moveq	#3,d0					; left lightning sound effect
		cmp.b	#1,MDDC_OffsLeft.w			; check if offset is 1
		beq.s	.offs1					; if yes, branch
		moveq	#4,d0					; right lightning sound effect
		cmp.b	#1,MDDC_OffsRight.w			; check if offset is 1
		beq.s	.offs1					; if yes, branch

		lea	MDDC_PalFinal(pc),a1			; use normal palette
		bra.s	.loadpal				; load it
; ------------------------------------------------------------------------------

.offs1
		jsr	MDDC_QueueSound(pc)			; queue lightning sound effect

		move.b	#14,MDDC_ShakeLen.w			; set screen shake length
		lea	MDDC_PalAni5(pc),a1			; brighter palette
		bra.s	.loadpal				; load it

.offs2
		lea	MDDC_PalAni6(pc),a1			; more brighter palette
; ------------------------------------------------------------------------------

.loadpal
		cmp.w	#MDDC_ScriptLightning&$FFFF,MDDC_ScriptPos+2.w; check if we can edit the palette yet
		blo.s	MDDC_Rts				; if not, skip it

MDDC_BrightBG =	*+1
		moveq	#0,d5					; check if brightness is changed
		beq.w	MDDC_Vint_LoadPal			; branch if nawt
	vdpComm	move.l,$0000,CRAM,WRITE,4(a6)			; CRAM WRITE $0000
; ------------------------------------------------------------------------------

		moveq	#16-1,d0				; do for all colors
		lea	MDDC_BrightTable(pc),a0			; load brightness table to a0
		move.b	-1(a0,d5.w),d5				; load offset from table to d5

		moveq	#$E,d4					; get the color mask to d4
		and.b	d5,d4					; get low color mask to d4
		and.b	#$E0,d5					; get high color mask to d5

.fadecol
		move.b	(a1),d1					; get blue to d1
		sub.b	d4,d1					; substract color offset
		bcc.s	.bluefine				; branch if carry clear
		moveq	#0,d1					; clear color

.bluefine
		lsl.w	#8,d1					; shift into place
		move.w	(a1)+,d2				; load the color value from RAM

		moveq	#$E,d3					; load color mask to d3
		and.w	d2,d3					; get red only to d3
		sub.b	d4,d3					; substract color offset
		bcs.s	.nored					; branch if carry set
		move.b	d3,d1					; save as low byte of color

.nored
		and.b	#$E0,d2					; get green only to d2
		sub.b	d5,d2					; usbstract color offset
		bcs.s	.nogreen				; branch if carry set
		or.b	d2,d1					; OR into the low byte of color

.nogreen
		move.w	d1,(a6)					; save to CRAM
		dbf	d0,.fadecol				; loop for all colors

MDDC_Rts:
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Fade out brightness table for background
; ------------------------------------------------------------------------------

MDDC_BrightTable: dc.b $02, $04, $24, $26, $46, $48, $68, $6A, $8A, $AA, $CC, $EE
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine to handle logo scrolling
; ------------------------------------------------------------------------------

MDDC_LogoScroll:
		subq.w	#1,MDDC_LogoScrollDelay.w		; check if still doing scrolling in
		bpl.s	MDDC_LogoScroll3			; branch if so

MDDC_LogoScroll2:
		move.w	#$8F04,4(a6)				; autoincrement 4

		not.b	*+5.w					; negate logo ripple position
		moveq	#0,d0					; copy logo position to d0
		clr.w	d0					; clear low word

	vdpComm	move.l,$F018,VRAM,WRITE,4(a6)			; VRAM WRITE $F018
		moveq	#132/2-1,d2				; load loop count to d2

.scroll2
		move.l	d0,(a6)					; write FG position to VDP
		dbf	d2,.scroll2				; loop
		rts
; ------------------------------------------------------------------------------

MDDC_LogoScroll3:
	; scale vertically
		addq.w	#1,*+6.w				; increase scale offset
		move.w	#-1,d0					; load scale offset to d0

		cmp.w	#44,d0					; check for max table
		bhs.s	.dis					; branch if more than that
		add.w	d0,d0					; double offset

		lea	MDDC_Scale_Data,a1			; load scale data array to a1
		move.l	a1,MDDC_HintCode+4.w			; copy to h-int code
; ------------------------------------------------------------------------------

	; wait until line 200 to do our business
		move.w	#$8F00,4(a6)				; autoincrement 0
	vdpComm	move.l,$0000,VSRAM,WRITE,4(a6)			; VSRAM write $0000
		move	#$2300,sr				; enable interrupts
		jsr	MDDC_LoadScaleJmp			; load scale data

.wait
		move.w	#$FF00,d1				; load mask to d1
		and.w	8(a6),d1				; AND H/V counter with mask
		cmp.w	#200<<8,d1				; check our line
		bne.s	.wait					; if not 200, loop

		move	#$2700,sr				; disable interrupts
		bra.s	.c
; ------------------------------------------------------------------------------

.dis
		move.w	#$8004,4(a6)				; disable h-int
	vdpComm	move.l,$0000,VSRAM,WRITE,4(a6)			; VSRAM write $0000
		move.w	#-8,(a6)				; set to -8
; ------------------------------------------------------------------------------

.c
	; handle scrolling
		move.w	#0,d4					; load angle to d4
		addq.w	#6,.c+2.w				; increment angle

MDDC_LogoMultiply =	*+2
		move.w	#$6000,d1				; set default value
		sub.w	#$58,MDDC_LogoMultiply.w		; decrease multiplier

		move.w	#$8F04,4(a6)				; autoincrement 4
		move.l	MDDC_SineTableRef,a0			; load sine table to a0
		move.w	#132/4-1,d2				; load loop count to d2
	vdpComm	move.l,$F018,VRAM,WRITE,4(a6)			; VRAM WRITE $F018

.scrollx
	rept 4
		moveq	#0,d3
		move.w	(a0,d4.w),d3				; load sine offset
		addq.w	#2,d4					; go to next sine entry
		and.w	#$1FE,d4				; keep in range

		muls	d1,d3					; multiply logo angle
		swap	d3					; get the upper word only
		move.w	d3,(a6)					; save scanline
	endr
		dbf	d2,.scrollx				; loop for all lines

		move.w	#$8F00,4(a6)				; autoincrement 0
	vdpComm	move.l,$0000,VSRAM,WRITE,4(a6)			; VSRAM write $0000
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Vertical interrupt routine to handle the ending visuals
; ------------------------------------------------------------------------------

MDDC_Vint_Logo:
		jsr	MDDC_Ani_Ctrl_Scrl(pc)			; handle animation and controller input and scroll
		beq.s	.rte					; branch if no anim change
		moveq	#6,d0
		jsr	MDDC_QueueSound(pc)			; queue type sound effect
		move.l	#.typedone,MDDC_VintAddr.w		; run the next animation code
		bra.s	.rte
; ------------------------------------------------------------------------------

.typedone
		jsr	MDDC_Ani_Ctrl_Scrl(pc)			; handle animation and controller input and scroll
		beq.s	.rte					; branch if no anim change
		ori.w	#$8000,MDDC_LogoPalette.w		; stop cycling
		move.l	#.exit,MDDC_VintAddr.w			; run the next animation code

.rte
		jsr	MDDC_LogoPalCycle(pc)			; run palette cycling
		rte
; ------------------------------------------------------------------------------

.exit
		jsr	MDDC_Ani_Ctrl_Scrl(pc)			; handle animation and controller input and scroll
		beq.s	.rte					; branch if no anim change
		st	MDDC_Exit				; exit screen
		rte
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine to handle logo palette cycle
; ------------------------------------------------------------------------------

MDDC_LogoPalCycle:
MDDC_LogoPalette = *+2
		move.w	#0,d0					; load delay value
		addq.w	#2,MDDC_LogoPalette.w			; go to next cycle
		sub.w	#24,d0					; check if the delay is done
		bcs.s	.rts					; branch if not
		and.w	#-4,d0					; clear extra bits

		moveq	#$30,d1					; load wrap value to d1
		moveq	#$48,d3					; load check value to d3
		bclr	#15,d0					; clear msb
		beq.s	.nomax					; if was clear, skip
		moveq	#-1,d3					; load check value to d3

.nomax
		cmp.w	d3,d0					; check for max value
		blo.s	.ok2					; branch if less than that
		sub.w	d1,MDDC_LogoPalette.w			; fix the palette offset

.ok2
		moveq	#$C/2-1,d2				; set loop count
		lea	MDDC_LogoCycle(pc),a0			; load cycle to a0
		move.l	#$C0480000,4(a6)			; CRAM WRITE $0048

.redo
		cmp.w	d3,d0					; check for max value
		blo.s	.ok					; branch if less than that
		sub.w	d1,d0					; substract loop amount
		bra.s	.redo					; check again

.ok
		move.l	(a0,d0.w),(a6)				; write into buffer
		addq.w	#4,d0					; add offset
		dbf	d2,.redo				; loop for all entries

.rts
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine to quickly load a palette to CRAM
; ------------------------------------------------------------------------------

MDDC_Vint_LoadPal:
	vdpComm	move.l,$0000,CRAM,WRITE,4(a6)			; CRAM WRITE $0000

MDDC_Vint_LoadPal2:
	rept 32/4
		move.l	(a1)+,(a6)				; write full palette line
	endr

MDDC_Vint_Rts:
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Vertical interrupt routine to handle animation and controller input
; ------------------------------------------------------------------------------

MDDC_Ani_Ctrl_Scrl:
		jsr	MDDC_LogoScroll(pc)			; run logo scroll first

MDDC_Ani_Ctrl:
		move	#$2700,sr				; disable interrupts
		move.w	#$8F02,4(a6)				; autoincrement 2

	; read joypad
		lea	$A10003,a0				; load joy1 to a0
		move.b	#0,(a0)
		or.l	d0,d0
		move.b	(a0),d0
		btst	#5,d0					; check if start was used
		seq	MDDC_Exit				; if yes, enable exit signaling
		move.b	#$40,(a0)
		or.l	d0,d0
		tst.b	(a0)

		lea	MDDC_ScriptPos.w,a2			; load main script to a2
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine to handle general scripts
; ------------------------------------------------------------------------------

MDDC_Vint_Script:
		subq.w	#1,4(a2)				; decrease delay counter
		bcs.s	.cont					; if underflowed, branch
		moveq	#0,d0					; Z = true
		rts

.cont
		addq.b	#1,6(a2)				; increase offset counter
		move.l	(a2),a0					; load script location to a0
		move.w	(a0)+,4(a2)				; load new delay to memory
; ------------------------------------------------------------------------------

		bclr	#7,4(a2)				; clear extra bits to check if palette needs loading
		beq.s	.nopal					; branch if not
		lea	MDDC_PalTable(pc),a1			; load palette table to a1
		add.w	(a0)+,a1				; load the specific list to load
		bsr.s	MDDC_Vint_LoadPal			; load palette to CRAM
; ------------------------------------------------------------------------------

.nopal
		bclr	#6,4(a2)				; clear extra bits to check if extra palette needs loading
		beq.s	.domap					; branch if not
	vdpComm	move.l,$0020,CRAM,WRITE,4(a6)			; CRAM WRITE $0020

		lea	MDDC_PalTable(pc),a1			; load palette table to a1
		add.w	(a0)+,a1				; load the specific list to load
		bsr.s	MDDC_Vint_LoadPal2			; load palette to CRAM

		lea	MDDC_PalTable(pc),a1			; load palette table to a1
		add.w	(a0)+,a1				; load the specific list to load
		bsr.w	MDDC_Vint_LoadPal2			;
; ------------------------------------------------------------------------------

.domap
		move.w	(a0)+,d0				; load the next VRAM address
		bpl.s	.normal					; if positive, it is indeed more data
		move.w	.tab(pc,d0.w),d0			; load the offset of end routine to run
		jmp	.tab(pc,d0.w)				; jump to it

.normal
		swap	d0					; swap because its a VDP command too
		clr.w	d0					; only write to first $4000 of VRAM, rip if we need more than that
		move.l	d0,4(a6)				; run VDP command
		move.w	(a0)+,d0				; load repeat counter

.write
		move.w	(a0)+,(a6)				; write 1 map entry at a time
		dbf	d0,.write				; loop for all entries
		bra.s	.domap					; go to next iteration
; ------------------------------------------------------------------------------

		dc.w .nextrout-.tab			; -4	; restart the animation at a specified point
		dc.w .save-.tab				; -2	; only save final address
.tab
; ------------------------------------------------------------------------------

.nextrout
		move.l	a0,(a2)					; save script address
		moveq	#-1,d0					; Z = false
		rts
; ------------------------------------------------------------------------------

.save
		move.l	a0,(a2)					; save script address
		moveq	#0,d0					; Z = true
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Main script data
; ------------------------------------------------------------------------------

MDDC_ScriptPos:	dc.l MDDC_ScriptData				; start at script data address
MDDC_Delay:	dc.l 0						; initialize counters to none

MDDC_ScriptData:
		; FRAME 1
		dc.w (2-1)|$8000, MDDC_PalAni0-MDDC_PalTable
		dc.w $4928, 1, $02A8, $0AA8
		dc.w $49A8, 1, $02A9, $02A9
		dc.w $4A28, 1, $02A9, $02A9
		dc.w $4AA8, 1, $02A9, $02A9
		dc.w $4B28, 1, $02AA, $02AA
		dc.w -2

		; FRAME 2
		dc.w (2-1)|$8000, MDDC_PalAni1-MDDC_PalTable
		dc.w $4926, 3, $02AB, $02AC, $02AC, $0AAB
		dc.w $49A6, 3, $02AD, $02AE, $02AF, $02AD
		dc.w $4A26, 3, $02AD, $0000, $02B0, $02AD
		dc.w $4AA6, 3, $02AD, $0000, $0000, $02AD
		dc.w $4B26, 3, $02B1, $0000, $0000, $02B1
		dc.w -4

		; FRAME 3
		dc.w (2-1)|$8000, MDDC_PalAni2-MDDC_PalTable
		dc.w $4924, 5, $02A8, $02AC, $02AC, $02AC, $02AC, $0AA8
		dc.w $49A4, 5, $02A9, $02B2, $02B3, $02AF, $02B4, $02A9
		dc.w $4A24, 5, $02A9, $02B5, $0000, $02B6, $02B7, $02A9
		dc.w $4AA4, 5, $02A9, $0000, $0000, $0000, $0000, $02A9
		dc.w $4B24, 5, $02AA, $0000, $0000, $0000, $0000, $02AA
		dc.w -2

		; FRAME 4
		dc.w (16-1)|$0000
		dc.w $4922, 1, $02A8, $02B8
		dc.w $492E, 1, $0AB8, $0AA8
		dc.w $49A2, 1, $02A9, $02B9
		dc.w $49AE, 1, $02BA, $02A9
		dc.w $4A22, 1, $02A9, $02BB
		dc.w $4A2E, 1, $02BC, $02A9
		dc.w $4AA2, 1, $02A9, $0000
		dc.w $4AAE, 1, $0000, $02A9
		dc.w $4B22, 1, $02AA, $0000
		dc.w $4B2E, 1, $0000, $02AA
		dc.w -2

		; FRAME 5
		dc.w (3-1)|$8000, MDDC_PalAni3-MDDC_PalTable
		dc.w $49A4, 5, $02BD, $02BE, $02BF, $02AF, $02C0, $02C1
		dc.w $4A24, 5, $02C2, $02C3, $0000, $02B0, $02C4, $02C5
		dc.w $4AA2, 0, $02C6
		dc.w $4AB0, 0, $02C7
		dc.w $4B22, 0, $02C8
		dc.w $4B30, 0, $02C9
		dc.w $4BA2, 0, $02CA
		dc.w $4BB0, 0, $02CB
		dc.w -2

		; FRAME 6
		dc.w (2-1)|$0000
		dc.w $4A1E, 0, $02CC
		dc.w $4A34, 0, $0ACC
		dc.w $4A9A, 6, $02CD, $02CE, $02CF, $02D0, $02C6, $02D1, $02D2
		dc.w $4AAC, 6, $0AD2, $0AD1, $0AC6, $0AD0, $0ACF, $0ACE, $0ACD
		dc.w $4B1C, 13, $02D3, $02D4, $02D5, $02C8, $02D6, $02D7, $02D8, $0AD8, $0AD7, $0AD6, $0AC8, $0AD5, $0AD4, $0AD3
		dc.w $4BA0, 9, $02D9, $02CA, $02DA, $02DB, $02DC, $0ADC, $0ADB, $0ADA, $0ACA, $0AD9
		dc.w -2

		; FRAME 7
		dc.w (3-1)|$0000
		dc.w $4916, 2, $02DD, $02DE, $02DF
		dc.w $4938, 2, $0ADF, $0ADE, $0ADD
		dc.w $4996, 3, $02E0, $02E1, $02E2, $02E3
		dc.w $49B6, 3, $0AE3, $0AE2, $0AE1, $0AE0
		dc.w $4A16, 3, $1AE3, $02E4, $02E5, $02E6
		dc.w $4A36, 3, $0AE6, $0AE5, $0AE4, $12E3
		dc.w $4A98, 0, $02E7
		dc.w $4ABA, 0, $0AE7
		dc.w -2

		; FRAME 8
		dc.w (2-1)|$0000
		dc.w $4798, 3, $02E8, $02E9, $02EA, $02EB
		dc.w $47B4, 3, $0AEB, $0AEA, $0AE9, $0AE8
		dc.w $4816, 5, $02EC, $02ED, $02EE, $02EF, $02F0, $02F0
		dc.w $4832, 5, $02F0, $02F0, $0AEF, $0AEE, $0AED, $0AEC
		dc.w $4896, 5, $02F1, $02F2, $02F3, $02F4, $02F5, $02F5
		dc.w $48B2, 5, $02F5, $02F5, $0AF4, $0AF3, $0AF2, $0AF1
		dc.w -2

		; FRAME 9
		dc.w (3-1)|$0000
		dc.w $471C, 13, $02F6, $02F7, $02F8, $02F9, $02FA, $02FB, $02FB, $02FB, $02FB, $0AFA, $0AF9, $0AF8, $0AF7, $0AF6
		dc.w $4822, 7, $02F0, $02FC, $02FD, $12AC, $12AC, $0AFD, $0AFC, $02F0
		dc.w $48A2, 7, $02F5, $02FE, $02FF, $0300, $0300, $0AFF, $0AFE, $02F5
		dc.w -2

		; FRAME 10
		dc.w (3-1)|$0000
		dc.w $4628, 1, $0301, $0B01
		dc.w $46A6, 3, $0302, $0303, $0B03, $0B02
		dc.w -2

		; FRAME 11
		dc.w (5-1)|$0000
		dc.w $45A8, 1, $0304, $0B04
		dc.w $4628, 1, $0305, $0B05
		dc.w $46A2, 7, $0306, $0307, $0308, $0309, $0B09, $0B08, $0B07, $0B06
		dc.w -2

		; FRAME 12
		dc.w (2-1)|$8000, MDDC_PalAni4-MDDC_PalTable
		dc.w -4

		; FRAME 13
		dc.w (2-1)|$8000, MDDC_PalAni5-MDDC_PalTable
		dc.w -2

		; FRAME 14
		dc.w (1-1)|$8000, MDDC_PalAni6-MDDC_PalTable
		dc.w -4

		; FRAME 15
		dc.w (2-1)|$C000, MDDC_PalAni7-MDDC_PalTable, MDDC_PalAni9-MDDC_PalTable, MDDC_PalAni9-MDDC_PalTable
		dc.w -2

		; FRAME 16
		dc.w (1-1)|$8000, MDDC_PalAni8-MDDC_PalTable
		dc.w -2

		; FRAME 17
		dc.w (1-1)|$8000, MDDC_PalAni9-MDDC_PalTable
		dc.w -4

		; FRAME 18
		dc.w (1-1)|$8000, MDDC_PalAni8-MDDC_PalTable
		dc.w -2

		; FRAME 19
		dc.w (2-1)|$8000, MDDC_PalAni7-MDDC_PalTable
		dc.w -2

		; FRAME 20
		dc.w (1-1)|$8000, MDDC_PalAni6-MDDC_PalTable
		dc.w -2

		; FRAME 21
		dc.w (2-1)|$8000, MDDC_PalAni5-MDDC_PalTable
		dc.w -4

		; FRAME 22
		dc.w (10-1)|$0000
		dc.w -2

MDDC_ScriptLightning:
		; FADE 1
		dc.w (5-1)|$4000, MDDC_LogoPal1A-MDDC_PalTable, MDDC_LogoPal1B-MDDC_PalTable
		dc.w -2

		; FADE 2
		dc.w (5-1)|$4000, MDDC_LogoPal2A-MDDC_PalTable, MDDC_LogoPal2B-MDDC_PalTable
		dc.w -2

		; FADE 3
		dc.w (5-1)|$4000, MDDC_LogoPal3A-MDDC_PalTable, MDDC_LogoPal3B-MDDC_PalTable
		dc.w -2

		; FADE 4
		dc.w (5-1)|$4000, MDDC_LogoPal4A-MDDC_PalTable, MDDC_LogoPal4B-MDDC_PalTable
		dc.w -2

		; FADE 5
		dc.w (5-1)|$4000, MDDC_LogoPal5A-MDDC_PalTable, MDDC_LogoPal5B-MDDC_PalTable
		dc.w -2

		; FADE 6
		dc.w (325-1)|$4000, MDDC_LogoPalFA-MDDC_PalTable, MDDC_LogoPalFB-MDDC_PalTable
		dc.w -2

	rept $C	; FG FADE
		dc.w (8-1)|$0000
		dc.w -4
	endr

		; CYCLE
		dc.w (25-1)|$0000
		dc.w -4

		; DISCORD 1
		dc.w (2-1)|$0000
		dc.w $4B28, 0, $23BF
		dc.w $4B2A, 0, $23BF
		dc.w $4BA8, 0, $23D2
		dc.w $4BAA, 0, $23D3
		dc.w $4C28, 0, $23E7
		dc.w $4C2A, 0, $23E8
		dc.w $4CA8, 0, $23FB
		dc.w $4CAA, 0, $23FC
		dc.w -4

		; DISCORD 2
		dc.w (2-1)|$0000
		dc.w $4B26, 0, $23BE
		dc.w $4B2C, 0, $23C0
		dc.w $4BA6, 0, $23D1
		dc.w $4BAC, 0, $23D4
		dc.w $4C26, 0, $23E6
		dc.w $4C2C, 0, $23E9
		dc.w $4CA6, 0, $23FA
		dc.w $4CAC, 0, $23FD
		dc.w -2

		; DISCORD 3
		dc.w (2-1)|$0000
		dc.w $4B24, 0, $23BD
		dc.w $4B2E, 0, $23C1
		dc.w $4BA4, 0, $23D0
		dc.w $4BAE, 0, $23D5
		dc.w $4C24, 0, $23E5
		dc.w $4C2E, 0, $23EA
		dc.w $4CA4, 0, $23F9
		dc.w $4CAE, 0, $23FE
		dc.w -2

		; DISCORD 4
		dc.w (2-1)|$0000
		dc.w $4B22, 0, $23BC
		dc.w $4B30, 0, $23C2
		dc.w $4BA2, 0, $23CF
		dc.w $4BB0, 0, $23D6
		dc.w $4C22, 0, $23E4
		dc.w $4C30, 0, $23EB
		dc.w $4CA2, 0, $23F8
		dc.w $4CB0, 0, $23FF
		dc.w -2

		; DISCORD 5
		dc.w (2-1)|$0000
		dc.w $4B20, 0, $23BB
		dc.w $4B32, 0, $23C3
		dc.w $4BA0, 0, $23CE
		dc.w $4BB2, 0, $23D7
		dc.w $4C20, 0, $23E3
		dc.w $4C32, 0, $23EC
		dc.w $4CA0, 0, $23F7
		dc.w $4CB2, 0, $2400
		dc.w -2

		; DISCORD 6
		dc.w (2-1)|$0000
		dc.w $4B1E, 0, $23BA
		dc.w $4B34, 0, $23C4
		dc.w $4B9E, 0, $23CD
		dc.w $4BB4, 0, $23D8
		dc.w $4C1E, 0, $23E2
		dc.w $4C34, 0, $23ED
		dc.w $4C9E, 0, $23F6
		dc.w $4CB4, 0, $2401
		dc.w -2

		; DISCORD 7
		dc.w (2-1)|$0000
		dc.w $4B1C, 0, $23B9
		dc.w $4B36, 0, $23C5
		dc.w $4B9C, 0, $23CC
		dc.w $4BB6, 0, $23D9
		dc.w $4C1C, 0, $23E1
		dc.w $4C36, 0, $23EE
		dc.w $4C9C, 0, $23F5
		dc.w $4CB6, 0, $2402
		dc.w -2

		; DISCORD 8
		dc.w (2-1)|$0000
		dc.w $4B1A, 0, $23B8
		dc.w $4B38, 0, $23C5
		dc.w $4B9A, 0, $23CB
		dc.w $4BB8, 0, $23DA
		dc.w $4C1A, 0, $23E0
		dc.w $4C38, 0, $23EA
		dc.w $4C9A, 0, $23F4
		dc.w $4CB8, 0, $23FE
		dc.w -2

		; DISCORD 9
		dc.w (2-1)|$0000
		dc.w $4B18, 0, $23B7
		dc.w $4B3A, 0, $23C6
		dc.w $4B98, 0, $23CA
		dc.w $4BBA, 0, $23DB
		dc.w $4C18, 0, $23DF
		dc.w $4C3A, 0, $23E7
		dc.w $4C98, 0, $23F3
		dc.w $4CBA, 0, $23FB
		dc.w -2

		; DISCORD 10
		dc.w (2-1)|$0000
		dc.w $4B16, 0, $23B6
		dc.w $4B3C, 0, $23C5
		dc.w $4B96, 0, $23C9
		dc.w $4BBC, 0, $23D9
		dc.w $4C16, 0, $23DE
		dc.w $4C3C, 0, $23EF
		dc.w $4C96, 0, $23F2
		dc.w $4CBC, 0, $2403
		dc.w -2

		; DISCORD 11
		dc.w (2-1)|$0000
		dc.w $4B14, 0, $23B5
		dc.w $4B3E, 0, $23C7
		dc.w $4B94, 0, $23C8
		dc.w $4BBE, 0, $23DC
		dc.w $4C14, 0, $23DD
		dc.w $4C3E, 0, $23F0
		dc.w $4C94, 0, $23F1
		dc.w $4CBE, 0, $2404
		dc.w -2

		; WAIT
		dc.w (200-1)|$0000
		dc.w -2

		; FADE 1
		dc.w (5-1)|$4000, MDDC_LogoPal1C-MDDC_PalTable, MDDC_LogoPal1D-MDDC_PalTable
		dc.w -2

		; FADE 2
		dc.w (5-1)|$4000, MDDC_LogoPal2C-MDDC_PalTable, MDDC_LogoPal2D-MDDC_PalTable
		dc.w -2

		; FADE 3
		dc.w (5-1)|$4000, MDDC_LogoPal3C-MDDC_PalTable, MDDC_LogoPal3D-MDDC_PalTable
		dc.w -2

		; FADE 4
		dc.w (5-1)|$4000, MDDC_LogoPal4C-MDDC_PalTable, MDDC_LogoPal4D-MDDC_PalTable
		dc.w -2

		; FADE 5
		dc.w (5-1)|$4000, MDDC_LogoPal5C-MDDC_PalTable, MDDC_LogoPal5D-MDDC_PalTable
		dc.w -2

		; FADE 6
		dc.w (60-1)|$4000, MDDC_LogoPal6C-MDDC_PalTable, MDDC_LogoPal6D-MDDC_PalTable
		dc.w -2

		; FADE 7
		dc.w (32-1)|$0000
		dc.w -4

		; EXIT
		dc.w $0FFF
		dc.w -4
; ==============================================================================
; ------------------------------------------------------------------------------
; Lightning script data
; ------------------------------------------------------------------------------

MDDC_ScriptNull:
		dc.w $0FFF
		dc.w -4

MDDC_ScriptLightLeft:
		; LIGHT 1
		dc.w (3-1)|$0000
		dc.w $428E, 3, $024B, $024C, $024D, $024E
		dc.w $4310, 1, $025D, $025E
		dc.w $4390, 0, $0266
		dc.w $4696, 0, $029C
		dc.w -2

		; LIGHT 2
		dc.w (3-1)|$0000
		dc.w $428C, 5, $0250, $0251, $0252, $0253, $0254, $0255
		dc.w $4310, 1, $025F, $0260
		dc.w $4390, 2, $0267, $0268, $0269
		dc.w $440C, 3, $0271, $0272, $0273, $0274
		dc.w $4490, 1, $027F, $0280
		dc.w $4510, 1, $0288, $0289
		dc.w $4592, 0, $028F
		dc.w $468C, 5, $029D, $029E, $029F, $02A0, $02A1, $02A2
		dc.w -2

		; LIGHT 3
		dc.w (3-1)|$0000
		dc.w $428A, 6, $024F, $0256, $0257, $0258, $0259, $025A, $025B
		dc.w $4310, 2, $0261, $0262, $0263
		dc.w $438E, 4, $026A, $026B, $026C, $026D, $026E
		dc.w $440A, 6, $0275, $0276, $0277, $0278, $0279, $027A, $027B
		dc.w $448E, 3, $0281, $0282, $0283, $0284
		dc.w $4510, 2, $028A, $028B, $028C
		dc.w $458E, 3, $0290, $0291, $0292, $0293
		dc.w $460E, 3, $0296, $0297, $0298, $0299
		dc.w $468E, 3, $02A3, $02A4, $02A5, $02A6
		dc.w -2

		; LIGHT 4
		dc.w (3-1)|$0000
		dc.w $428A, 6, $00D5, $00D6, $00D7, $00D8, $025C, $00DA, $00DB
		dc.w $4310, 2, $0264, $0265, $00E5
		dc.w $438E, 4, $00FA, $026F, $0270, $00FD, $00FE
		dc.w $440A, 6, $010B, $010C, $010D, $027C, $027D, $027E, $0111
		dc.w $448E, 3, $0120, $0285, $0286, $0287
		dc.w $4510, 2, $028D, $028E, $0135
		dc.w $458E, 3, $0145, $0294, $0295, $0148
		dc.w $460E, 3, $0157, $0158, $029A, $029B
		dc.w $468C, 5, $016A, $016B, $016C, $016D, $02A7, $016F
		dc.w -2

		; LIGHT 5
		dc.w (3-1)|$0000
		dc.w $4292, 0, $00D9
		dc.w $4310, 1, $00E5, $00E5
		dc.w $4390, 1, $00FB, $00FC
		dc.w $4410, 2, $010E, $010F, $0110
		dc.w $4490, 2, $0121, $00E5, $0122
		dc.w $4510, 1, $0133, $0134
		dc.w $4590, 1, $0146, $0147
		dc.w $4612, 1, $0159, $015A
		dc.w $4694, 0, $016E
		dc.w -4

MDDC_ScriptLightRight:
		; LIGHT 1
		dc.w (3-1)|$0000
		dc.w $42BE, 3, $0A4E, $0A4D, $0A4C, $0A4B
		dc.w $4340, 1, $0A5E, $0A5D
		dc.w $43C2, 0, $0A66
		dc.w $46BC, 0, $0A9C
		dc.w -2

		; LIGHT 2
		dc.w (3-1)|$0000
		dc.w $42BC, 5, $0A55, $0A54, $0A53, $0A52, $0A51, $0A50
		dc.w $4340, 1, $0A60, $0A5F
		dc.w $43BE, 2, $0269, $0A68, $0A67
		dc.w $4440, 3, $0A74, $0A73, $0A72, $0A71
		dc.w $44C0, 1, $0A80, $0A7F
		dc.w $4540, 1, $0A89, $0A88
		dc.w $45C0, 0, $0A8F
		dc.w $46BC, 5, $0AA2, $0AA1, $0AA0, $0A9F, $0A9E, $0A9D
		dc.w -2

		; LIGHT 3
		dc.w (3-1)|$0000
		dc.w $42BC, 6, $0A5B, $0A5A, $0A59, $0A58, $0A57, $0A56, $0A4F
		dc.w $433E, 2, $0A63, $0A62, $0A61
		dc.w $43BC, 4, $0A6E, $0A6D, $0A6C, $0A6B, $0A6A
		dc.w $443C, 6, $0A7B, $0A7A, $0A79, $0A78, $0A77, $0A76, $0A75
		dc.w $44BE, 3, $0A84, $0A83, $0A82, $0A81
		dc.w $453E, 2, $0A8C, $0A8B, $0A8A
		dc.w $45BE, 3, $0A93, $0A92, $0A91, $0A90
		dc.w $463E, 3, $0A99, $0A98, $0A97, $0A96
		dc.w $46BE, 3, $0AA6, $0AA5, $0AA4, $0AA3
		dc.w -2

		; LIGHT 4
		dc.w (3-1)|$0000
		dc.w $42BC, 6, $08DB, $08DA, $0A5C, $08D8, $08D7, $08D6, $08D5
		dc.w $433E, 2, $08E5, $0A65, $0A64
		dc.w $43BC, 4, $08FE, $08FD, $0A70, $0A6F, $08FA
		dc.w $443C, 6, $0911, $0A7E, $0A7D, $0A7C, $090D, $090C, $090B
		dc.w $44BE, 3, $0A87, $0A86, $0A85, $0920
		dc.w $453E, 2, $0935, $0A8E, $0A8D
		dc.w $45BE, 3, $0948, $0A95, $0A94, $0945
		dc.w $463E, 3, $0A9B, $0A9A, $0958, $0957
		dc.w $46BC, 5, $096F, $0AA7, $096D, $096C, $096B, $096A
		dc.w -2

		; LIGHT 5
		dc.w (3-1)|$0000
		dc.w $42C0, 0, $08D9
		dc.w $4340, 1, $08E5, $08E5
		dc.w $43C0, 1, $08FC, $08FB
		dc.w $443E, 2, $0910, $090F, $090E
		dc.w $44BE, 2, $0922, $08E5, $0921
		dc.w $4540, 1, $0934, $0933
		dc.w $45C0, 1, $0947, $0946
		dc.w $463E, 1, $095A, $0959
		dc.w $46BE, 0, $096E
		dc.w -4
; ==============================================================================
; ------------------------------------------------------------------------------
; Array for screen shake data
; ------------------------------------------------------------------------------

MDDC_ShakeArray:
		dc.b 1, 2, 1, 0, 1, 2, 2, 1, 2, 0, 1, 2, 1, 2, 0, 0	; $10
		dc.b 2, 0, 1, 2, 2, 3, 2, 2, 1, 2, 0, 0, 1, 0, 1, 2	; $20
		dc.b 1, 2, 1, 0, 1, 2, 2, 1, 2, 0, 1, 2, 1, 2, 0, 0	; $30
		dc.b 2, 0, 1, 2, 2, 1, 2, 2, 1, 2, 0, 0, 1, 0, 1, 2	; $40
; ==============================================================================
; ------------------------------------------------------------------------------
; Palette tables for animation
; ------------------------------------------------------------------------------

MDDC_PalTable:
MDDC_PalFinal:	dc.w $000, $200, $402, $404, $604, $824, $A24, $C24, $C44, $E44, $E66, $C88, $88C, $6AE, $AEE, $EEE
MDDC_PalAni0:	dc.w $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $C88, $88C
MDDC_PalAni1:	dc.w $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $88C, $88C, $6AE
MDDC_PalAni2:	dc.w $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $88C, $6AE, $AEE
MDDC_PalAni3:	dc.w $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $88C, $6AE, $AEE, $EEE
MDDC_PalAni4:	dc.w $000, $000, $000, $000, $000, $000, $000, $402, $404, $604, $824, $E44, $88C, $AEE, $EEE, $EEE
MDDC_PalAni5:	dc.w $000, $200, $402, $404, $604, $824, $A24, $C24, $E44, $E66, $C88, $88C, $6AE, $AEE, $EEE, $EEE
MDDC_PalAni6:	dc.w $404, $404, $604, $824, $A24, $C44, $E44, $E66, $C88, $88C, $6AE, $AEE, $EEE, $EEE, $EEE, $EEE
MDDC_PalAni7:	dc.w $C44, $C44, $E44, $E66, $C88, $C88, $88C, $6AE, $6AE, $AEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE
MDDC_PalAni8:	dc.w $C88, $C88, $88C, $6AE, $6AE, $6AE, $AEE, $AEE, $AEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE
MDDC_PalAni9:	dc.w $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE

MDDC_LogoPal1A:	dc.w $000, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $CCC, $AAA, $EEE, $EEC, $EEE, $CCE, $EEE, $EEE, $EEE
MDDC_LogoPal2A:	dc.w $000, $EEE, $EEE, $EEE, $EEE, $EEE, $CCC, $AAA, $888, $EEE, $ECA, $EEE, $AAE, $EEE, $CEE, $AEC
MDDC_LogoPal3A:	dc.w $000, $EEE, $EEE, $EEE, $EEE, $CCC, $AAA, $888, $666, $EEC, $EA8, $CCE, $88E, $EEE, $AEC, $8EA
MDDC_LogoPal4A:	dc.w $000, $EEE, $EEE, $EEE, $CCC, $AAA, $888, $666, $444, $ECA, $E86, $AAE, $66E, $CEC, $8EA, $6EC
MDDC_LogoPal5A:	dc.w $000, $EEE, $EEE, $CCC, $AAA, $888, $666, $444, $222, $CA8, $C64, $88C, $44E, $ACA, $6C8, $4C6
MDDC_LogoPalFA:	dc.w $000, $EEE, $CCC, $AAA, $888, $666, $444, $222, $000, $A86, $A42, $66A, $22C, $8A8, $4A6, $2A4
MDDC_LogoPal1C:	dc.w $000, $CCC, $AAA, $888, $666, $444, $222, $000, $000, $864, $820, $448, $00A, $686, $284, $082
MDDC_LogoPal2C:	dc.w $000, $AAA, $888, $666, $444, $222, $000, $000, $000, $642, $600, $226, $008, $464, $062, $060
MDDC_LogoPal3C:	dc.w $000, $888, $666, $444, $222, $000, $000, $000, $000, $420, $400, $004, $006, $242, $040, $040
MDDC_LogoPal4C:	dc.w $000, $666, $444, $222, $000, $000, $000, $000, $000, $200, $200, $002, $004, $020, $020, $020
MDDC_LogoPal5C:	dc.w $000, $444, $222, $000, $000, $000, $000, $000, $000, $000, $000, $000, $002, $000, $000, $000
MDDC_LogoPal6C:	dc.w $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000

MDDC_LogoPal1B:	dc.w $000, $EEE, $EEE, $EEE, $CEE, $EEE, $CEE, $EEE, $CEE, $EEE, $CEE, $EEE, $CEE, $EEE, $CEE, $EEE
MDDC_LogoPal2B:	dc.w $000, $EEE, $EEE, $EEE, $AEC, $CEE, $AEC, $CEE, $AEC, $CEE, $AEC, $CEE, $AEC, $CEE, $AEC, $CEE
MDDC_LogoPal3B:	dc.w $000, $EEE, $EEE, $EEE, $8EA, $AEC, $8EA, $AEC, $8EA, $AEC, $8EA, $AEC, $8EA, $AEC, $8EA, $AEC
MDDC_LogoPal4B:	dc.w $000, $EEE, $EEE, $EEE, $6EC, $8EA, $6EC, $8EA, $6EC, $8EA, $6EC, $8EA, $6EC, $8EA, $6EC, $8EA
MDDC_LogoPal5B:	dc.w $000, $EEE, $EEE, $CCC, $4C6, $6C8, $4C6, $6C8, $4C6, $6C8, $4C6, $6C8, $4C6, $6C8, $4C6, $6C8
MDDC_LogoPal1D:	dc.w $000, $CCC, $AAA, $888
MDDC_LogoPal2D:	dc.w $000, $AAA, $888, $666
MDDC_LogoPal3D:	dc.w $000, $888, $666, $444
MDDC_LogoPal4D:	dc.w $000, $666, $444, $222
MDDC_LogoPal5D:	dc.w $000, $444, $222, $000
MDDC_LogoPal6D:	dc.w $000, $000, $000, $000
MDDC_LogoPalFB:	dc.w $000, $EEE, $CCC, $AAA
MDDC_LogoCycle:	dc.w $2A4, $4A6, $2A4, $4A6, $2A4, $4A6, $2A4, $4A6, $2A4, $4A6, $2A4, $4A6
		dc.w $00C, $008, $04C, $04A, $08E, $06E, $0AE, $0AC, $0EE, $0CC, $2A6, $0A6
		dc.w $2A0, $280, $880, $840, $E60, $E20, $E44, $A24, $A08, $806, $60A, $408
		dc.w $00C, $008, $04C, $04A, $08E, $06E, $0AE, $0AC, $0EE, $0CC, $2A6, $0A6
		dc.w $2A0, $280, $880, $840, $E60, $E20, $E44, $A24, $A08, $806, $60A, $408
		dc.w $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000, $000
		dc.w $000, $000, $000, $000
; ==============================================================================
; ------------------------------------------------------------------------------
; code for the Z80 sound driver
; ------------------------------------------------------------------------------

	opt ae-
SoundDriver:
	z80prog 0						; start a new z80 program
		include "Z80.asm"				; include Z80 sound driver
SoundDriver_Sz:
	z80prog
	even
; ------------------------------------------------------------------------------
