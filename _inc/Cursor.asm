; ---------------------------------------------------------------------------
; Code for the mouse cursor
; ---------------------------------------------------------------------------

MousePointer:
		clr.b	(v_mouse_gfxindex).w		; NTP: reset cursor gfx index

		move.w	(v_mouse_inputx).w,d0
		move.w	(v_mouse_inputy).w,d1
		move.w	(v_mouse_screenx).w,d2
		move.w	(v_mouse_screeny).w,d3
		move.b	(v_mouse_velx).w,d4
		move.b	(v_mouse_vely).w,d5
		ext.w	d4
		ext.w	d5

		cmpi.b	#id_Special,(v_gamemode).w
		beq.s	@nospeedup
		tst.w	(v_player+shoetime).w
		beq.s	@nospeedup

		cmpi.w	#$FFFF,d0
		bne.s	@divx
		moveq	#0,d0
	@divx:
		asr.w	#1,d0

		cmpi.w	#$FFFF,d1
		bne.s	@divy
		moveq	#0,d1
	@divy:
		asr.w	#1,d1
		add.w	(v_mouse_inputx).w,d0
		add.w	(v_mouse_inputy).w,d1

	@nospeedup:
		add.w 	d0,d2
		add.w	d4,d2
		bpl.s	@plusx
		moveq	#0,d2
		moveq	#0,d4

	@plusx:
		cmpi.w	#319,d2
		blo.s	@blomaxx
		move.w	#319,d2
		moveq	#0,d4

	@blomaxx:
		add.w	d1,d3
		add.w	d5,d3
		bpl.s	@plusy
		moveq	#0,d3
		moveq	#0,d5

	@plusy:
		cmpi.w	#223,d3
		blo.s	@blomaxy
		move.w	#223,d3
		moveq	#0,d5

	@blomaxy:
		move.w	d2,(v_mouse_screenx).w
		move.w	d3,(v_mouse_screeny).w

		add.w	(v_screenposx).w,d2
		add.w	(v_screenposy).w,d3
		move.w	d2,(v_mouse_worldx).w
		move.w	d3,(v_mouse_worldy).w

		tst.w	d4
		beq.s	@xvelzero
		bpl.s	@xvelpos
		add.w	d0,d4
		addq.w	#1,d4
		bmi.s	@xvelzero
		bra.s	@xvelclr

	@xvelpos:
		add.w	d0,d4
		subq.w	#1,d4
		bpl.s	@xvelzero

	@xvelclr:
		moveq	#0,d4

	@xvelzero:
		move.b	d4,(v_mouse_velx).w

		tst.w	d5
		beq.s	@yvelzero
		bpl.s	@yvelpos
		add.w	d1,d5
		addq.w	#1,d5
		bmi.s	@yvelzero
		bra.s	@yvelclr

	@yvelpos:
		add.w	d1,d5
		subq.w	#1,d5
		bpl.s	@yvelzero

	@yvelclr:
		moveq	#0,d5

	@yvelzero:
		move.b	d5,(v_mouse_vely).w

		move.b	(v_mouse_press).w,d0
		btst.l	#1,d0
		beq.s	@nopressa
		bset.b	#bitA,(v_jpadpress1).w

	@nopressa:
		btst.l	#3,d0
		beq.s	@nopressstart
		bset.b	#bitStart,(v_jpadpress1).w

	@nopressstart:
		move.b	(v_mouse_hold).w,d0
		btst.l	#1,d0
		beq.s	@noholda
		bset.b	#bitA,(v_jpadhold1).w

	@noholda:
		btst.l	#3,d0
		beq.s	@noholdstart
		bset.b	#bitStart,(v_jpadhold1).w

	@noholdstart:
		tst.w	(v_player+invtime).w
		bne.s	@nothurt2

		subq.b	#1,(v_mouse_hurttimer).w
		bmi.s	@nothurt1

		bclr.b	#0,(v_mouse_hold).w
		bclr.b	#0,(v_mouse_press).w
		bra.s	@noclick

	@nothurt1:
		sf	(v_mouse_hurttimer).w
		bra.s	@nothurt3

	@nothurt2:
		st	(v_mouse_hurttimer).w

	@nothurt3:
		move.b	(v_mouse_hold).w,d0
		or.b	(v_mouse_press).w,d0
		btst.l	#0,d0
		beq.s	@noclick
		addq.b	#2,(v_mouse_gfxindex).w

	@noclick:
