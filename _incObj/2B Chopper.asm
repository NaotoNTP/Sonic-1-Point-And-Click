; ---------------------------------------------------------------------------
; Object 2B - Chopper enemy (GHZ)
; ---------------------------------------------------------------------------

Chopper:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Chop_Index(pc,d0.w),d1
		jsr	Chop_Index(pc,d1.w)
		bra.w	RememberState
; ===========================================================================
Chop_Index:	dc.w Chop_Main-Chop_Index
		dc.w Chop_ChgSpeed-Chop_Index

chop_origY:	equ $30
; ===========================================================================

Chop_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Chop,obMap(a0)
		move.w	#$47B,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#9,obColType(a0)
		move.b	#$10,obActWid(a0)
		move.w	#-$700,obVelY(a0) ; set vertical speed
		move.w	obY(a0),chop_origY(a0) ; save original position

Chop_ChgSpeed:	; Routine 2
		lea	(Ani_Chop).l,a1
		bsr.w	AnimateSprite
		
		moveq	#$10,d2
		moveq	#$20,d3
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
		sfx	sfx_ActionBlock
		move.w	#-$27C,obVelY(a0)
		
	@nomouse:
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)	; reduce speed
		move.w	chop_origY(a0),d0
		cmp.w	obY(a0),d0	; has Chopper returned to its original position?
		bcc.s	@chganimation	; if not, branch
		move.w	d0,obY(a0)
		move.w	#-$700,obVelY(a0) ; set vertical speed

	@chganimation:
		move.b	#1,obAnim(a0)	; use fast animation
		subi.w	#$C0,d0
		cmp.w	obY(a0),d0
		bcc.s	@nochg
		move.b	#0,obAnim(a0)	; use slow animation
		tst.w	obVelY(a0)	; is Chopper at	its highest point?
		bmi.s	@nochg		; if not, branch
		move.b	#2,obAnim(a0)	; use stationary animation

	@nochg:
		rts	