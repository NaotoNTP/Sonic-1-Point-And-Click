; ---------------------------------------------------------------------------
; Subroutine to	display	a sprite/object, when a0 is the	object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DisplaySprite:
		moveq	#0,d0
		move.b	obPriority(a0),d0 ; get sprite priority
		add.b	d0,d0
		movea.w	DisplaySpriteTab(pc,d0.w),a1
		move.w	(a1),d0
		cmpi.w	#$7E,d0		; is this part of the queue full?
		bhs.s	DSpr_Full	; if yes, branch
		addq.w	#2,(a1)		; increment sprite count
		move.w	a0,2(a1,d0.w)	; insert RAM address for object

	DSpr_Full:
		rts	

; End of function DisplaySprite


; ---------------------------------------------------------------------------
; Subroutine to	display	a 2nd sprite/object, when a1 is	the object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DisplaySprite1:
		moveq	#0,d0
		move.b	obPriority(a1),d0 ; get sprite priority
		add.b	d0,d0
		movea.w	DisplaySpriteTab(pc,d0.w),a2
		move.w	(a2),d0
		cmpi.w	#$7E,d0		; is this part of the queue full?
		bhs.s	DSpr1_Full	; if yes, branch
		addq.w	#2,(a2)		; increment sprite count
		move.w	a1,2(a2,d0.w)	; insert RAM address for object

	DSpr1_Full:
		rts	

; End of function DisplaySprite1

DisplaySpriteTab:
	dc.w	v_spritequeue
	dc.w	v_spritequeue+$80
	dc.w	v_spritequeue+$100
	dc.w	v_spritequeue+$180
	dc.w	v_spritequeue+$200
	dc.w	v_spritequeue+$280
	dc.w	v_spritequeue+$300
	dc.w	v_spritequeue+$380