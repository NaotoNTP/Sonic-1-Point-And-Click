; ---------------------------------------------------------------------------
; Object 42 - Newtron enemy (GHZ)
; ---------------------------------------------------------------------------

Newtron:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Newt_Index(pc,d0.w),d1
		jmp	Newt_Index(pc,d1.w)
; ===========================================================================
Newt_Index:	dc.w Newt_Main-Newt_Index
		dc.w Newt_Action-Newt_Index
		dc.w Newt_Delete-Newt_Index
; ===========================================================================

Newt_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Newt,obMap(a0)
		move.w	#$49B,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$14,obActWid(a0)
		move.b	#$10,obHeight(a0)
		move.b	#8,obWidth(a0)

Newt_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		lea	(Ani_Newt).l,a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================
@index:		dc.w @chkdistance-@index
		dc.w @type00-@index
		dc.w @matchfloor-@index
		dc.w @speed-@index
		dc.w @type01-@index
; ===========================================================================

@chkdistance:
		bset	#0,obStatus(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bcc.s	@sonicisright
		neg.w	d0
		bclr	#0,obStatus(a0)

	@sonicisright:
		moveq	#$10,d2
		moveq	#$20,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@nomouse1
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@nomouse1
		bset.b	#0,(v_mouse_gfxindex).w
		bra.s	@mousehover

	@nomouse1:
		cmpi.w	#$80,d0		; is Sonic within $80 pixels of	the newtron?
		bcc.s	@outofrange	; if not, branch

	@mousehover:
		addq.b	#2,ob2ndRout(a0) ; goto @type00 next
		move.b	#1,obAnim(a0)
		tst.b	obSubtype(a0)	; check	object type
		beq.s	@istype00	; if type is 00, branch

		move.w	#$249B,obGfx(a0)
		move.b	#8,ob2ndRout(a0) ; goto @type01 next
		move.b	#4,obAnim(a0)	; use different	animation

	@outofrange:
	@istype00:
		rts
; ===========================================================================

@type00:
		moveq	#$14,d2
		moveq	#$28,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@nomouse3
		moveq	#$10,d2
		moveq	#$20,d3
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@nomouse3
		bset.b	#0,(v_mouse_gfxindex).w
		btst.b	#0,(v_mouse_press).w
		beq.s	@nomouse3
		move.b	#id_ExplosionItem,0(a0) ; change object to explosion
		move.b	#0,obRoutine(a0)
		addq.l	#4,sp
		moveq	#10,d0
		jsr	AddPoints
		bra.w	ExplosionItem

	@nomouse3:
		cmpi.b	#4,obFrame(a0)	; has "appearing" animation finished?
		bcc.s	@fall		; is yes, branch
		bset	#0,obStatus(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bcc.s	@sonicisright2
		bclr	#0,obStatus(a0)

	@sonicisright2:
		rts
; ===========================================================================

	@fall:
		cmpi.b	#1,obFrame(a0)
		bne.s	@loc_DE42
		move.b	#$C,obColType(a0)

	@loc_DE42:
		bsr.w	ObjectFall
		bsr.w	ObjFloorDist
		tst.w	d1		; has newtron hit the floor?
		bpl.s	@keepfalling	; if not, branch

		add.w	d1,obY(a0)
		move.w	#0,obVelY(a0)	; stop newtron falling
		addq.b	#2,ob2ndRout(a0)
		move.b	#2,obAnim(a0)
		btst	#5,obGfx(a0)
		beq.s	@pppppppp
		addq.b	#1,obAnim(a0)

	@pppppppp:
		move.b	#$D,obColType(a0)
		move.w	#$200,obVelX(a0) ; move newtron horizontally
		btst	#0,obStatus(a0)
		bne.s	@keepfalling
		neg.w	obVelX(a0)

	@keepfalling:
		rts
; ===========================================================================

@matchfloor:
		moveq	#$14,d2
		moveq	#$28,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@nomouse4
		moveq	#8,d2
		moveq	#$10,d3
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@nomouse4
		bset.b	#0,(v_mouse_gfxindex).w
		btst.b	#0,(v_mouse_press).w
		beq.s	@nomouse4
		move.b	#id_ExplosionItem,0(a0) ; change object to explosion
		move.b	#0,obRoutine(a0)
		addq.l	#4,sp
		moveq	#10,d0
		jsr	AddPoints
		bra.w	ExplosionItem

	@nomouse4:
		bsr.w	SpeedToPos
		bsr.w	ObjFloorDist
		cmpi.w	#-8,d1
		blt.s	@nextroutine
		cmpi.w	#$C,d1
		bge.s	@nextroutine
		add.w	d1,obY(a0)	; match	newtron's position with floor
		rts
; ===========================================================================

	@nextroutine:
		addq.b	#2,ob2ndRout(a0) ; goto @speed next
		rts
; ===========================================================================

@speed:
		moveq	#$14,d2
		moveq	#$28,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@nomouse5
		moveq	#8,d2
		moveq	#$10,d3
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@nomouse5
		bset.b	#0,(v_mouse_gfxindex).w
		btst.b	#0,(v_mouse_press).w
		beq.s	@nomouse5
		move.b	#id_ExplosionItem,0(a0) ; change object to explosion
		move.b	#0,obRoutine(a0)
		addq.l	#4,sp
		moveq	#10,d0
		jsr	AddPoints
		bra.w	ExplosionItem

	@nomouse5:
		bsr.w	SpeedToPos
		rts
; ===========================================================================

@type01:
		moveq	#$10,d2
		moveq	#$20,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@nomouse2
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@nomouse2
		bset.b	#0,(v_mouse_gfxindex).w
		btst.b	#0,(v_mouse_press).w
		beq.s	@nomouse2
		move.b	#id_ExplosionItem,0(a0) ; change object to explosion
		move.b	#0,obRoutine(a0)
		addq.l	#4,sp
		moveq	#10,d0
		jsr	AddPoints
		bra.w	ExplosionItem

	@nomouse2:
		cmpi.b	#1,obFrame(a0)
		bne.s	@firemissile
		move.b	#$C,obColType(a0)

	@firemissile:
		cmpi.b	#2,obFrame(a0)
		bne.s	@fail
		tst.b	$32(a0)
		bne.s	@fail
		move.b	#1,$32(a0)
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_Missile,0(a1) ; load missile object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		subq.w	#8,obY(a1)
		move.w	#$200,obVelX(a1)
		move.w	#$14,d0
		btst	#0,obStatus(a0)
		bne.s	@noflip
		neg.w	d0
		neg.w	obVelX(a1)

	@noflip:
		add.w	d0,obX(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.b	#1,obSubtype(a1)

	@fail:
		rts
; ===========================================================================

Newt_Delete:	; Routine 4
		bra.w	DeleteObject
