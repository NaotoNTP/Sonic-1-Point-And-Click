; ---------------------------------------------------------------------------
; Object 4B - giant ring for entry to special stage
; ---------------------------------------------------------------------------

GiantRing:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	GRing_Index(pc,d0.w),d1
		jmp	GRing_Index(pc,d1.w)
; ===========================================================================
GRing_Index:	dc.w GRing_Main-GRing_Index
		dc.w GRing_Animate-GRing_Index
		dc.w GRing_Collect-GRing_Index
		dc.w GRing_Delete-GRing_Index
; ===========================================================================

GRing_Main:	; Routine 0
		move.l	#Map_GRing,obMap(a0)
		move.w	#$2400,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$40,obActWid(a0)
		tst.b	obRender(a0)
		bpl.s	GRing_Animate
		cmpi.b	#6,(v_emeralds).w ; do you have 6 emeralds?
		beq.w	GRing_Delete	; if yes, branch
		cmpi.w	#50,(v_rings).w	; do you have at least 50 rings?
		bcc.s	GRing_Okay	; if yes, branch
		rts	
; ===========================================================================

GRing_Okay:
		addq.b	#2,obRoutine(a0)
		move.b	#2,obPriority(a0)
		move.b	#$52,obColType(a0)
		move.w	#$C40,(v_gfxbigring).w	; Signal that Art_BigRing should be loaded ($C40 is the size of Art_BigRing)

GRing_Animate:	; Routine 2
		moveq	#$20,d2
		moveq	#$40,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@nomouse
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@nomouse
		bset.b	#0,(v_mouse_gfxindex).w
		btst.b	#0,(v_mouse_press).w
		beq.s	@nomouse
		bra.s	GRing_Explode
		
	@nomouse:
		move.b	(v_ani1_frame).w,obFrame(a0)
		out_of_range	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================

GRing_Collect:	; Routine 4
		subq.b	#2,obRoutine(a0)
		move.b	#0,obColType(a0)
		bsr.w	FindFreeObj
		bne.w	GRing_PlaySnd
		move.b	#id_RingFlash,0(a1) ; load giant ring flash object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.l	a0,$3C(a1)
		move.w	(v_player+obX).w,d0
		cmp.w	obX(a0),d0	; has Sonic come from the left?
		bcs.s	GRing_PlaySnd	; if yes, branch
		bset	#0,obRender(a1)	; reverse flash	object

GRing_PlaySnd:
		sfx	sfx_BigRing	; play giant ring sound
		bra.w	GRing_Animate
; ===========================================================================

GRing_Explode:
		sfx	sfx_RingLoss
		lea	GRing_Spill,a3
		moveq	#31,d5
		
	@loop:
		bsr.w	FindFreeObj
		bne.s	GRing_Delete
		move.b	#id_RingLoss,0(a1) ; load bouncing ring object
		addq.b	#2,obRoutine(a1)
		move.b	#8,obHeight(a1)
		move.b	#8,obWidth(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.l	#Map_Ring,obMap(a1)
		move.w	#$27B2,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#3,obPriority(a1)
		move.b	#$47,obColType(a1)
		move.b	#8,obActWid(a1)
		move.b	#-1,(v_ani3_time).w
		move.b	#1,obStatus(a1)
		move.w 	(a3)+,$10(a1) ; move the data contained in the array to the x velocity and increment the address in a3
		move.w	(a3)+,$12(a1) ; move the data contained in the array to the y velocity and increment the address in a3
		dbf	d5,@loop	; repeat for number of rings (max 31)
		
GRing_Delete:	; Routine 6
		bra.w	DeleteObject
		
; ===========================================================================
; ---------------------------------------------------------------------------
; Ring Spawn Array
; ---------------------------------------------------------------------------
GRing_Spill:	dc.w	$FF3C,$FC14,$00C4,$FC14,$FDC8,$FCB0,$0238,$FCB0
		dc.w	$FCB0,$FDC8,$0350,$FDC8,$FC14,$FF3C,$03EC,$FF3C
		dc.w	$FC14,$00C4,$03EC,$00C4,$FCB0,$0238,$0350,$0238
		dc.w	$FDC8,$0350,$0238,$0350,$FF3C,$03EC,$00C4,$03EC
		dc.w	$FF9E,$FE0A,$0062,$FE0A,$FEE4,$FE58,$011C,$FE58
		dc.w	$FE58,$FEE4,$01A8,$FEE4,$FE0A,$FF9E,$01F6,$FF9E
		dc.w	$FE0A,$0062,$01F6,$0062,$FE58,$011C,$01A8,$011C
		dc.w	$FEE4,$01A8,$011C,$01A8,$FF9E,$01F6,$0062,$01F6
		even
; ===========================================================================
