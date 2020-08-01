; ---------------------------------------------------------------------------
; Object 7D - hidden points at the end of a level
; ---------------------------------------------------------------------------

HiddenBonus:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Bonus_Index(pc,d0.w),d1
		jmp	Bonus_Index(pc,d1.w)
; ===========================================================================
Bonus_Index:	dc.w Bonus_Main-Bonus_Index
		dc.w Bonus_Display-Bonus_Index

bonus_timelen:	equ $30		; length of time to display bonus sprites
; ===========================================================================

Bonus_Main:	; Routine 0
		moveq	#$10,d2
		moveq	#$20,d3
		move.w	(v_mouse_worldx).w,d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@chkdel
		move.w	(v_mouse_worldy).w,d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@chkdel
		bset.b	#0,(v_mouse_gfxindex).w
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Bonus,obMap(a0)
		move.w	#$84B6,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#0,obPriority(a0)
		move.b	#$10,obActWid(a0)
		move.b	obSubtype(a0),obFrame(a0)
		move.w	#119,bonus_timelen(a0) ; set display time to 2 seconds
		sfx	sfx_Bonus	; play bonus sound
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		move.w	Bns_points(pc,d0.w),d0 ; load bonus points array
		jsr	(AddPoints).l

	@chkdel:
		out_of_range.s	@delete
		rts	

	@delete:
		jmp	(DeleteObject).l

; ===========================================================================
Bns_points:	dc.w 0			; Bonus	points array
		dc.w 1000
		dc.w 100
		dc.w 10
; ===========================================================================

Bonus_Display:	; Routine 2
		subq.w	#1,bonus_timelen(a0) ; decrement display time
		bmi.s	@del		; if time is zero, branch
		out_of_range.s	@del
		jmp	(DisplaySprite).l

	@del:	
		jmp	(DeleteObject).l