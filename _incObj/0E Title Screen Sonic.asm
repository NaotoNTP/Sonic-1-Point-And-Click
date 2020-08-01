; ---------------------------------------------------------------------------
; Object 0E - Sonic on the title screen
; ---------------------------------------------------------------------------

TitleSonic:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	TSon_Index(pc,d0.w),d1
		jmp	TSon_Index(pc,d1.w)
; ===========================================================================
TSon_Index:	dc.w TSon_Main-TSon_Index
		dc.w TSon_Delay-TSon_Index
		dc.w TSon_Move-TSon_Index
		dc.w TSon_Animate-TSon_Index
; ===========================================================================

TSon_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$F8,obX(a0)
		move.w	#$DE,obScreenY(a0) ; position is fixed to screen
		move.l	#Map_TSon,obMap(a0)
		move.w	#$2300,obGfx(a0)
		move.b	#1,obPriority(a0)
		move.b	#29,obDelayAni(a0) ; set time delay to 0.5 seconds
		lea	(Ani_TSon).l,a1
		bsr.w	AnimateSprite

TSon_Delay:	;Routine 2
		subq.b	#1,obDelayAni(a0) ; subtract 1 from time delay
		bpl.s	@wait		; if time remains, branch
		addq.b	#2,obRoutine(a0) ; go to next routine
		bra.w	DisplaySprite

	@wait:
		rts	
; ===========================================================================

TSon_Move:	; Routine 4
		subq.w	#8,obScreenY(a0) ; move Sonic up
		cmpi.w	#$96,obScreenY(a0) ; has Sonic reached final position?
		bne.s	@display	; if not, branch
		addq.b	#2,obRoutine(a0)

	@display:
		bra.w	DisplaySprite
; ===========================================================================

TSon_Animate:	; Routine 6
		moveq	#$24,d2
		move.w	d2,d3
		add.w	d3,d3
		move.w	(v_mouse_screenx).w,d0
		subi.w	#$A0,d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.s	@nohover
		move.w	(v_mouse_screeny).w,d1
		subi.w	#$44,d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.s	@nohover
		bset.b	#0,(v_mouse_gfxindex).w
		
	@nohover:
		lea	(Ani_TSon).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite