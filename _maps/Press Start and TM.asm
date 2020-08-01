; ---------------------------------------------------------------------------
; Sprite mappings - "PRESS START BUTTON" and "TM" from title screen
; ---------------------------------------------------------------------------
Map_PSB_internal:
		dc.w byte_A7CD-Map_PSB_internal
		dc.w M_PSB_PSB-Map_PSB_internal
		dc.w M_PSB_Limiter-Map_PSB_internal
		dc.w M_PSB_TM-Map_PSB_internal
M_PSB_PSB:	dc.b 6			; "PRESS START BUTTON"
byte_A7CD:	
	spritePiece	$10, 0, 2, 1, $F4, 0, 0, 0, 0
	spritePiece	$20, 0, 2, 1, $F3, 0, 0, 0, 0
	spritePiece	$30, 0, 1, 1, $F6, 0, 0, 0, 0
	
	spritePiece	$40, 0, 2, 1, $F1, 0, 0, 0, 0
	
	spritePiece	$58, 0, 4, 1, $F0, 0, 0, 0, 0
	spritePiece	$78, 0, 1, 1, $F4, 0, 0, 0, 0
M_PSB_Limiter:	dc.b $1E		; sprite line limiter
		dc.b $B8, $F, 0, 0, $80
		dc.b $B8, $F, 0, 0, $80
		dc.b $B8, $F, 0, 0, $80
		dc.b $B8, $F, 0, 0, $80
		dc.b $B8, $F, 0, 0, $80
		dc.b $B8, $F, 0, 0, $80
		dc.b $B8, $F, 0, 0, $80
		dc.b $B8, $F, 0, 0, $80
		dc.b $B8, $F, 0, 0, $80
		dc.b $B8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $D8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
		dc.b $F8, $F, 0, 0, $80
M_PSB_TM:	dc.b 1			; "TM"
		dc.b $FC, 4, 0,	0, $F8
		even