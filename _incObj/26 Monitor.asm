; ---------------------------------------------------------------------------
; Object 26 - monitors
; ---------------------------------------------------------------------------

Monitor:
		tst.b	(v_signpost).w
		beq.s	@normal
		btst.b	#2,obStatus(a0)
		beq.s	@fail
		cmpi.b	#9,obAnim(a0)
		beq.s	@fail
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_PowerUp,0(a1) ; load monitor contents object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obAnim(a0),obAnim(a1)
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_ExplosionItem,0(a1) ; load explosion object
		addq.b	#2,obRoutine(a1) ; don't create an animal
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)

	@fail:
		bra.w	DeleteObject
	
	@normal:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Mon_Index(pc,d0.w),d1
		jmp	Mon_Index(pc,d1.w)
; ===========================================================================
Mon_Index:	dc.w Mon_Main-Mon_Index
		dc.w Mon_Solid-Mon_Index
		dc.w Mon_BreakOpen-Mon_Index
		dc.w Mon_Animate-Mon_Index
		dc.w Mon_Display-Mon_Index
; ===========================================================================

Mon_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#$E,obHeight(a0)
		move.b	#$E,obWidth(a0)
		move.l	#Map_Monitor,obMap(a0)
		move.w	#$680,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$F,obActWid(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)	; has monitor been broken?
		beq.s	@notbroken	; if not, branch
		move.b	#8,obRoutine(a0) ; run "Mon_Display" routine
		move.b	#$B,obFrame(a0)	; use broken monitor frame
		rts	
; ===========================================================================

	@notbroken:
		move.b	#$46,obColType(a0)
		move.b	obSubtype(a0),obAnim(a0)

Mon_Solid:	; Routine 2
		btst.b	#4,obStatus(a0)
		beq.s	@skip
		
		bra.w	Mon_Animate
	
	@skip:
		tst.b	obStatus(a0)
		bmi.s	@fall
		move.b	ob2ndRout(a0),d0 ; is monitor set to fall?
		beq.w	@normal		; if not, branch
		subq.b	#2,d0
		bne.s	@fall

		; 2nd Routine 2
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		bsr.w	ExitPlatform
		btst	#3,obStatus(a1) ; is Sonic on top of the monitor?
		bne.w	@ontop		; if yes, branch
		clr.b	ob2ndRout(a0)
		bra.w	Mon_Animate
; ===========================================================================

	@ontop:
		move.w	#$10,d3
		move.w	obX(a0),d2
		bsr.w	MvSonicOnPtfm
		bra.w	Mon_Animate
; ===========================================================================

@fall:		; 2nd Routine 4
		bsr.w	ObjectFall
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.w	Mon_Animate
		add.w	d1,obY(a0)
		tst.b	obStatus(a0)
		bmi.s	@thrown
		
		clr.w	obVelY(a0)
		clr.b	ob2ndRout(a0)
		bra.w	Mon_Animate
; ===========================================================================
	@thrown:
		bclr.b	#7,obStatus(a0)
		move.w	obVelX(a0),d0
		muls.w	d0,d0
		move.w	obVelY(a0),d1
		muls.w	d1,d1
		add.l	d0,d1
		cmpi.l #$A00000,d1
		blt.s	@nobreak
		move.b	#4,obRoutine(a0)
		bra.w	Mon_Animate
; ===========================================================================
	
	@nobreak:
		move.b	#$46,obColType(a0)
		clr.w	obVelX(a0)
		clr.w	obVelY(a0)
		clr.b	ob2ndRout(a0)
		bra.w	Mon_Animate
; ===========================================================================

@normal:	; 2nd Routine 0
		move.w	#$1A,d1
		move.w	#$F,d2
		bsr.w	Mon_SolidSides
		beq.w	loc_A25C
		tst.w	obVelY(a1)
		bmi.s	loc_A20A
		cmpi.b	#id_Roll,obAnim(a1) ; is Sonic rolling?
		beq.s	loc_A25C	; if yes, branch

loc_A20A:
		tst.w	d1
		bpl.s	loc_A220
		sub.w	d3,obY(a1)
		bsr.w	loc_74AE
		move.b	#2,ob2ndRout(a0)
		bra.w	Mon_Animate
; ===========================================================================

loc_A220:
		tst.w	d0
		beq.w	loc_A246
		bmi.s	loc_A230
		tst.w	obVelX(a1)
		bmi.s	loc_A246
		bra.s	loc_A236
; ===========================================================================

loc_A230:
		tst.w	obVelX(a1)
		bpl.s	loc_A246

loc_A236:
		sub.w	d0,obX(a1)
		move.w	#0,obInertia(a1)
		move.w	#0,obVelX(a1)

loc_A246:
		btst	#1,obStatus(a1)
		bne.s	loc_A26A
		bset	#5,obStatus(a1)
		bset	#5,obStatus(a0)
		bra.s	Mon_Animate
; ===========================================================================

loc_A25C:
		btst	#5,obStatus(a0)
		beq.s	Mon_Animate
		move.w	#1,obAnim(a1)	; clear obAnim and set obNextAni to 1

loc_A26A:
		bclr	#5,obStatus(a0)
		bclr	#5,obStatus(a1)

Mon_Animate:	; Routine 6
		lea	(Ani_Monitor).l,a1
		bsr.w	AnimateSprite
		
		cmpi.b	#9,obAnim(a0)
		beq.w	Mon_Display
		moveq	#0,d4
		
		moveq	#$E,d2
		moveq	#$1C,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@nohover
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@nohover
		addq.b	#1,d4
		
	@nohover:
		btst.b	#0,(v_mouse_press).w
		beq.s	@nopress
		addq.b	#2,d4
	
	@nopress:
		btst.b	#0,(v_mouse_hold).w
		beq.s	@nohold
		addq.b	#4,d4
		
	@nohold:
		btst.b	#4,obStatus(a0)
		beq.s	@notclicked
		addq.b	#8,d4
	
	@notclicked:
		add.w	d4,d4
		move.w	@index(pc,d4.w),d4
		jmp	@index(pc,d4.w)
; ===========================================================================
@index:		dc.w @display-@index
		dc.w @glow-@index
		dc.w @display-@index
		dc.w @clicked-@index
		dc.w @display-@index
		dc.w @glow-@index
		dc.w @display-@index
		dc.w @clicked-@index
		dc.w @clrdisplay-@index
		dc.w @clrglow-@index
		dc.w @held-@index
		dc.w @held-@index
		dc.w @held-@index
		dc.w @held-@index
		dc.w @held-@index
		dc.w @held-@index
; ===========================================================================
	
	@clrglow:
		bset.b	#0,(v_mouse_gfxindex).w
		
	@clrdisplay:
		bset.b	#7,obStatus(a0)
		bclr.b	#4,obStatus(a0)
		bra.s	@display
; ===========================================================================	
	
	@clicked:
		bset.b	#2,obStatus(a0)
		bset.b	#4,obStatus(a0)	
		sfx	sfx_UnkB8
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		bset.b	#0,2(a2,d0.w)
		move.b	#0,obColType(a0)
		bclr.b	#3,(v_player+obStatus).w
		
	@held:
		move.w	(v_mouse_worldx).w,obX(a0)
		move.w	(v_mouse_worldy).w,obY(a0)
		move.b	(v_mouse_inputx+1).w,obVelX(a0)
		move.b	(v_mouse_inputy+1).w,obVelY(a0)
		asr.w	obVelX(a0)
		asr.w	obVelY(a0)
		
	@glow:
		bset.b	#0,(v_mouse_gfxindex).w
	
	@display:
; ===========================================================================

Mon_Display:	; Routine 8
		bsr.w	DisplaySprite
		out_of_range	DeleteObject
		rts	
; ===========================================================================

Mon_BreakOpen:	; Routine 4
		addq.b	#2,obRoutine(a0)
		move.b	#0,obColType(a0)
		bsr.w	FindFreeObj
		bne.s	Mon_Explode
		move.b	#id_PowerUp,0(a1) ; load monitor contents object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obAnim(a0),obAnim(a1)

Mon_Explode:
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_ExplosionItem,0(a1) ; load explosion object
		addq.b	#2,obRoutine(a1) ; don't create an animal
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)

	@fail:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		bset	#0,2(a2,d0.w)
		move.b	#9,obAnim(a0)	; set monitor type to broken
		bra.w	DisplaySprite
