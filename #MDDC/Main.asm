; ==============================================================================
; ------------------------------------------------------------------------------
; Main initialization for MDDC screen
; ------------------------------------------------------------------------------
		include "#MDDC/Macro.asm"			; include built-in constant and macros

MDDC_Main:
		move	#$2700,sr				; disable interrupts
		lea	$C00004,a6				; load VDP command port to a6
		move.w	#$8004,(a6)				; MODE 1 register
		move.w	#$8238,(a6)				; Plane A address $E000
		move.w	#$8400,(a6)				; Plane B address $0000
		move.w	#$857A,(a6)				; Sprite address $F400
		move.w	#$8D3C,(a6)				; Hscroll address $F000
		move.w	#$8700,(a6)				; set background color to 0x0
		move.w	#$8B03,(a6)				; set horizontal to 1 line and vertical scroll to full
; ------------------------------------------------------------------------------

		move.w	#$8F01,(a6)				; set autoincrement to 1
		move.l	#$94FF93FF,(a6)				; DMA length is entire VRAM
		move.w	#$9780,(a6)				;
		move.l	#$40000080,(a6)				; VRAM fill at 0
		move.w	#0,-4(a6)				; fill with 0

.loop2		move.w	(a6),d1					; load VDP status to d1
		btst	#1,d1					; check if busy
		bne.s	.loop2					; branch if yes
		move.w	#$8F02,(a6)				; set autoincrement to 2

		move.l	#$40000010,(a6)				; VSRAM WRITE 0
		subq.w	#4,a6					; VDP data port
		move.l	#0,(a6)					; set to 0
; ------------------------------------------------------------------------------

		move.w	#$1000/32-1,d0				; load plane size to d0
		move.l	#$00800080,d1				; load blank tile data
		move.l	#$60000003,4(a6)			; VRAM WRITE $E000
		bsr.s	MDDC_ClearVRAM				; clear it

		move.w	#$380/32-1,d0				; load horizontal scroll table length
		move.l	#$0000FFF8,d1				; load scroll position
		move.l	#$70000003,4(a6)			; VRAM WRITE $F000
		bsr.s	MDDC_ClearVRAM				; clear it

		move.l	#$40000010,4(a6)			; VSRAM WRITE 0
		move.w	#-4,(a6)				; save BG and FG offset
; ------------------------------------------------------------------------------

		lea	MDDC_Background_Map(pc),a0		; background mappings address
		lea	$FFFF0000,a1				; target in RAM (loaded later on)
		move.w	#$80,d0					; skip Plane A
		jsr	MDDC_EniDec				; decompress it

		lea	MDDC_Logo_Map(pc),a0			; logo mappings address
		lea	$FFFF09A0,a1				; target in RAM (loaded later on)
		move.w	#$2A8,d0				; skip some tiles
		jsr	MDDC_EniDec				; decompress it
; ------------------------------------------------------------------------------

		lea	MDDC_RAM_Code,a0			; compressed code segment
		lea	MDDC_Start,a1				; address in RAM for it
		jsr	MDDC_KosDec				; decompress it

		move.l	#MDDC_SineTable,MDDC_SineTableRef	; copy the sine table reference
		move.w	#$4EF9,MDDC_LoadScaleJmp		; jmp $.l
		move.l	#MDDC_LoadScale,MDDC_LoadScaleJmp+2	; copy the scale load reference
		jmp	MDDC_Start				; run the code
; ==============================================================================
; ------------------------------------------------------------------------------
; Clear some VRAM data
; ------------------------------------------------------------------------------

MDDC_ClearVRAM:
	rept 32/4
		move.l	d1,(a6)					; set 16 bytes at once
	endr
		dbf	d0,MDDC_ClearVRAM			; loop until scroll is done
		rts
; ==============================================================================
; ------------------------------------------------------------------------------
; Various file includes
; ------------------------------------------------------------------------------

MDDC_Background_Map:	incbin "#MDDC/Data/Background Map.eni"
MDDC_Logo_Map:		incbin "#MDDC/Data/Logo Map.eni"
MDDC_RAM_Code:		incbin "#MDDC/RAM.kos"
		even
; ==============================================================================
; ------------------------------------------------------------------------------
; MDDC logo scale table
; ------------------------------------------------------------------------------

MDDC_LoadScale:
		lea	MDDC_ScaleTable(pc),a0			; load table to a0
		move.w	(a0,d0.w),d0				; load offset from table to d0
		lea	(a0,d0.w),a0				; load data to a0
		moveq	#0,d0					; clear offset
		jmp	MDDC_EniDec				; decompress it
; ------------------------------------------------------------------------------

MDDC_ScaleTable:
		dcb.w 12, MDDC_ScaleNull-MDDC_ScaleTable
		dc.w MDDC_Scale0-MDDC_ScaleTable, MDDC_Scale1-MDDC_ScaleTable
		dc.w MDDC_Scale2-MDDC_ScaleTable, MDDC_Scale3-MDDC_ScaleTable
		dc.w MDDC_Scale3-MDDC_ScaleTable, MDDC_Scale5-MDDC_ScaleTable
		dc.w MDDC_Scale5-MDDC_ScaleTable, MDDC_Scale7-MDDC_ScaleTable
		dc.w MDDC_Scale7-MDDC_ScaleTable, MDDC_Scale9-MDDC_ScaleTable
		dc.w MDDC_Scale10-MDDC_ScaleTable, MDDC_Scale11-MDDC_ScaleTable
		dc.w MDDC_Scale12-MDDC_ScaleTable, MDDC_Scale13-MDDC_ScaleTable
		dc.w MDDC_Scale14-MDDC_ScaleTable, MDDC_Scale15-MDDC_ScaleTable
		dc.w MDDC_Scale16-MDDC_ScaleTable, MDDC_Scale17-MDDC_ScaleTable
		dc.w MDDC_Scale18-MDDC_ScaleTable, MDDC_Scale19-MDDC_ScaleTable
		dc.w MDDC_Scale20-MDDC_ScaleTable, MDDC_Scale21-MDDC_ScaleTable
		dc.w MDDC_Scale22-MDDC_ScaleTable, MDDC_Scale23-MDDC_ScaleTable
		dc.w MDDC_Scale24-MDDC_ScaleTable, MDDC_Scale25-MDDC_ScaleTable
		dc.w MDDC_Scale26-MDDC_ScaleTable, MDDC_Scale27-MDDC_ScaleTable
		dc.w MDDC_Scale28-MDDC_ScaleTable, MDDC_Scale29-MDDC_ScaleTable
		dc.w MDDC_Scale30-MDDC_ScaleTable, MDDC_Scale31-MDDC_ScaleTable
; ------------------------------------------------------------------------------

MDDC_ScaleNull:	incbin "#MDDC/Scale/32.eni"
MDDC_Scale0:	incbin "#MDDC/Scale/0.eni"
MDDC_Scale1:	incbin "#MDDC/Scale/1.eni"
MDDC_Scale2:	incbin "#MDDC/Scale/2.eni"
MDDC_Scale3:	incbin "#MDDC/Scale/3.eni"
MDDC_Scale4:	incbin "#MDDC/Scale/4.eni"
MDDC_Scale5:	incbin "#MDDC/Scale/5.eni"
MDDC_Scale6:	incbin "#MDDC/Scale/6.eni"
MDDC_Scale7:	incbin "#MDDC/Scale/7.eni"
MDDC_Scale8:	incbin "#MDDC/Scale/8.eni"
MDDC_Scale9:	incbin "#MDDC/Scale/9.eni"
MDDC_Scale10:	incbin "#MDDC/Scale/10.eni"
MDDC_Scale11:	incbin "#MDDC/Scale/11.eni"
MDDC_Scale12:	incbin "#MDDC/Scale/12.eni"
MDDC_Scale13:	incbin "#MDDC/Scale/13.eni"
MDDC_Scale14:	incbin "#MDDC/Scale/14.eni"
MDDC_Scale15:	incbin "#MDDC/Scale/15.eni"
MDDC_Scale16:	incbin "#MDDC/Scale/16.eni"
MDDC_Scale17:	incbin "#MDDC/Scale/17.eni"
MDDC_Scale18:	incbin "#MDDC/Scale/18.eni"
MDDC_Scale19:	incbin "#MDDC/Scale/19.eni"
MDDC_Scale20:	incbin "#MDDC/Scale/20.eni"
MDDC_Scale21:	incbin "#MDDC/Scale/21.eni"
MDDC_Scale22:	incbin "#MDDC/Scale/22.eni"
MDDC_Scale23:	incbin "#MDDC/Scale/23.eni"
MDDC_Scale24:	incbin "#MDDC/Scale/24.eni"
MDDC_Scale25:	incbin "#MDDC/Scale/25.eni"
MDDC_Scale26:	incbin "#MDDC/Scale/26.eni"
MDDC_Scale27:	incbin "#MDDC/Scale/27.eni"
MDDC_Scale28:	incbin "#MDDC/Scale/28.eni"
MDDC_Scale29:	incbin "#MDDC/Scale/29.eni"
MDDC_Scale30:	incbin "#MDDC/Scale/30.eni"
MDDC_Scale31:	incbin "#MDDC/Scale/31.eni"
; ------------------------------------------------------------------------------
