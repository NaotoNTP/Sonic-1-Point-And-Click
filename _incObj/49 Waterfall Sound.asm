; ---------------------------------------------------------------------------
; Object 49 - waterfall	sound effect (GHZ)
; ---------------------------------------------------------------------------

WaterSound:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	WSnd_Index(pc,d0.w),d1
		jmp	WSnd_Index(pc,d1.w)
; ===========================================================================
WSnd_Index:	dc.w WSnd_Main-WSnd_Index
		dc.w WSnd_PlaySnd-WSnd_Index
; ===========================================================================

WSnd_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#4,obRender(a0)

WSnd_PlaySnd:	; Routine 2
	; this is to avoid overwriting any other sfx
		tst.b	(v_waterfall_unpause).w
		beq.s	@check
		sf	(v_waterfall_unpause).w
		move.b	#sfx_UnkAB,mQueue+2.w
		bra.s	WSnd_ChkDel
		
	@check:	
		tst.b	mQueue+2.w		; check if any sound was queued
		bne.s	WSnd_ChkDel		; if was, skip
		move.b	#sfx_Waterfall,mQueue+2.w; else, play this again
		
		
	WSnd_ChkDel:
		out_of_range	DeleteObject
		rts
