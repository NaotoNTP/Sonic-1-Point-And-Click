; ---------------------------------------------------------------------------
; Object 41 - springs
; ---------------------------------------------------------------------------

Springs:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Spring_Index(pc,d0.w),d1
		jsr	Spring_Index(pc,d1.w)
		bsr.w	DisplaySprite
		out_of_range	DeleteObject
		rts
; ===========================================================================
Spring_Index:	dc.w Spring_Main-Spring_Index
		dc.w Spring_Up-Spring_Index
		dc.w Spring_AniUp-Spring_Index
		dc.w Spring_ResetUp-Spring_Index
		dc.w Spring_LR-Spring_Index
		dc.w Spring_AniLR-Spring_Index
		dc.w Spring_ResetLR-Spring_Index
		dc.w Spring_Dwn-Spring_Index
		dc.w Spring_AniDwn-Spring_Index
		dc.w Spring_ResetDwn-Spring_Index

spring_pow:	equ $30			; power of current spring

Spring_Powers:	dc.w -$1000		; power	of red spring
		dc.w -$A00		; power	of yellow spring
; ===========================================================================

Spring_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Spring,obMap(a0)
		move.w	#$523,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#4,obPriority(a0)
		move.b	obSubtype(a0),d0
		btst	#4,d0		; does the spring face left/right?
		beq.s	Spring_NotLR	; if not, branch

		move.b	#8,obRoutine(a0) ; use "Spring_LR" routine
		move.b	#1,obAnim(a0)
		move.b	#3,obFrame(a0)
		move.w	#$533,obGfx(a0)
		move.b	#8,obActWid(a0)

	Spring_NotLR:
		btst	#5,d0		; does the spring face downwards?
		beq.s	Spring_NotDwn	; if not, branch

		move.b	#$E,obRoutine(a0) ; use "Spring_Dwn" routine
		bset	#1,obStatus(a0)

	Spring_NotDwn:
		btst	#1,d0
		beq.s	loc_DB72
		bset	#5,obGfx(a0)

loc_DB72:
		andi.w	#$F,d0
		move.w	Spring_Powers(pc,d0.w),spring_pow(a0)
		rts
; ===========================================================================

Spring_Up:	; Routine 2
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		tst.b	obSolid(a0)	; is Sonic on top of the spring?
		bne.s	Spring_BounceUp	; if yes, branch

		moveq	#$E,d2
		moveq	#$1C,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@return
		moveq	#8,d2
		moveq	#$10,d3
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@return
		bset.b	#0,(v_mouse_gfxindex).w
		btst.b	#0,(v_mouse_press).w
		beq.s	@return
		bra.s	Spring_BounceMouseUp

	@return:
		rts
; ===========================================================================

Spring_BounceUp:
		addq.b	#2,obRoutine(a0)
		addq.w	#8,obY(a1)
		move.w	spring_pow(a0),obVelY(a1) ; move Sonic upwards
		bset	#1,obStatus(a1)
		bclr	#3,obStatus(a1)
		move.b	#id_Spring,obAnim(a1) ; use "bouncing" animation
		move.b	#2,obRoutine(a1)
		bclr	#3,obStatus(a0)
		clr.b	obSolid(a0)
		sfx	sfx_Spring	; play spring sound

Spring_AniUp:	; Routine 4
		lea	(Ani_Spring).l,a1
		bra.w	AnimateSprite
; ===========================================================================

Spring_BounceMouseUp:
		addq.b	#2,obRoutine(a0)
		bclr	#3,obStatus(a0)
		move.w	spring_pow(a0),d0
		move.w	d0,(v_mouse_vely).w
		add.w	d0,(v_mouse_vely).w
		asr.w	#1,d0
		add.w	d0,(v_mouse_vely).w
		sfx	sfx_Spring	; play spring sound
		bra.s	Spring_AniUp
; ===========================================================================

Spring_ResetUp:	; Routine 6
		move.b	#1,obNextAni(a0) ; reset animation
		subq.b	#4,obRoutine(a0) ; goto "Spring_Up" routine
		rts
; ===========================================================================

Spring_LR:	; Routine 8
		move.w	#$13,d1
		move.w	#$E,d2
		move.w	#$F,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,obRoutine(a0)
		bne.s	loc_DC0C
		move.b	#8,obRoutine(a0)

loc_DC0C:
		btst	#5,obStatus(a0)
		bne.s	Spring_BounceLR

		moveq	#8,d2
		moveq	#$10,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@return
		moveq	#$E,d2
		moveq	#$1C,d3
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@return
		bset.b	#0,(v_mouse_gfxindex).w
		btst.b	#0,(v_mouse_press).w
		beq.s	@return
		bra.s	Spring_BounceMouseLR

	@return:
		rts
; ===========================================================================

Spring_BounceLR:
		addq.b	#2,obRoutine(a0)
		move.w	spring_pow(a0),obVelX(a1) ; move Sonic to the left
		addq.w	#8,obX(a1)
		btst	#0,obStatus(a0)	; is object flipped?
		bne.s	Spring_Flipped	; if yes, branch
		subi.w	#$10,obX(a1)
		neg.w	obVelX(a1)	; move Sonic to	the right

	Spring_Flipped:
		move.w	#$F,$3E(a1)
		move.w	obVelX(a1),obInertia(a1)
		bchg	#0,obStatus(a1)
		btst	#2,obStatus(a1)
		bne.s	loc_DC56
		move.b	#id_Walk,obAnim(a1)	; use walking animation

loc_DC56:
		bclr	#5,obStatus(a0)
		bclr	#5,obStatus(a1)
		sfx	sfx_Spring	; play spring sound

Spring_AniLR:	; Routine $A
		lea	(Ani_Spring).l,a1
		bra.w	AnimateSprite
; ===========================================================================

Spring_BounceMouseLR:
		addq.b	#2,obRoutine(a0)
		move.w	spring_pow(a0),d0	; move Sonic to the left
		btst	#0,obStatus(a0)	; is object flipped?
		bne.s	@flipped	; if yes, branch
		neg.w	d0	; move Sonic to	the right

	@flipped:
		move.w	d0,(v_mouse_velx).w
		add.w	d0,(v_mouse_velx).w
		asr.w	#1,d0
		add.w	d0,(v_mouse_velx).w
		sfx	sfx_Spring	; play spring sound
		bra.s	Spring_AniLR
; ===========================================================================

Spring_ResetLR:	; Routine $C
		move.b	#2,obNextAni(a0) ; reset animation
		subq.b	#4,obRoutine(a0) ; goto "Spring_LR" routine
		rts
; ===========================================================================

Spring_Dwn:	; Routine $E
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,obRoutine(a0)
		bne.s	loc_DCA4
		move.b	#$E,obRoutine(a0)

loc_DCA4:
		tst.b	obSolid(a0)
		bne.s	@return
		tst.w	d4
		bmi.s	Spring_BounceDwn

		moveq	#$E,d2
		moveq	#$1C,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@return
		moveq	#8,d2
		moveq	#$10,d3
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@return
		bset.b	#0,(v_mouse_gfxindex).w
		btst.b	#0,(v_mouse_press).w
		beq.s	@return
		bra.s	Spring_BounceMouseDwn

	@return:
		rts
; ===========================================================================

Spring_BounceDwn:
		addq.b	#2,obRoutine(a0)
		subq.w	#8,obY(a1)
		move.w	spring_pow(a0),obVelY(a1)
		neg.w	obVelY(a1)	; move Sonic downwards
		bset	#1,obStatus(a1)
		bclr	#3,obStatus(a1)
		move.b	#2,obRoutine(a1)
		bclr	#3,obStatus(a0)
		clr.b	obSolid(a0)
		sfx	sfx_Spring	; play spring sound

Spring_AniDwn:	; Routine $10
		lea	(Ani_Spring).l,a1
		bra.w	AnimateSprite
; ===========================================================================

Spring_BounceMouseDwn:
		addq.b	#2,obRoutine(a0)
		bclr	#3,obStatus(a0)
		move.w	spring_pow(a0),d0
		neg.w	d0
		move.w	d0,(v_mouse_vely).w
		add.w	d0,(v_mouse_vely).w
		asr.w	#1,d0
		add.w	d0,(v_mouse_vely).w
		sfx	sfx_Spring	; play spring sound
		bra.s	Spring_AniDwn
; ==========================================================================

Spring_ResetDwn:
		; Routine $12
		move.b	#1,obNextAni(a0) ; reset animation
		subq.b	#4,obRoutine(a0) ; goto "Spring_Dwn" routine
		rts
