; ==============================================================================
; ------------------------------------------------------------------------------
; Equates and macros
; ------------------------------------------------------------------------------

	rsset 0
MDDC_cVol		rs.b 4					; channel volume (1 per operator)
MDDC_cChannel		rs.b 1					; channel bits
MDDC_cPtr		rs.w 1					; pointer to channel tracker
MDDC_cFlags		rs.b 1					; various flags and key mask
MDDC_cDelay		rs.b 1					; tracker delay
MDDC_cFreq		rs.w 1					; channel frequency
MDDC_cLoop		rs.b 1					; loop counter
MDDC_cVibStr		rs.w 1					; vibrato pointer store
MDDC_cVolStr		rs.w 1					; volume pointer store
MDDC_cVibPtr		rs.b 6					; vibrato pointer
MDDC_cVolPtr		rs.b 6					; volume pointer
MDDC_cSize		rs.b 0					; channel size

	rsset 4
MDDC_Queue		rs.b 1					; queued sound
MDDC_FM1		rs.b MDDC_cSize				; FM 1 data
MDDC_FM2		rs.b MDDC_cSize				; FM 2 data
MDDC_FM3		rs.b MDDC_cSize				; FM 3 data
.test			rs.b 0					; listings help

writeYMX		macro part, reg, value
	if narg>2
		ld	a,\reg					; copy register to a
	endif
		ld	(4000h+\part), a			; send register to YM command
	if narg>2
		ld	a,\value				; load value
	else
		ld	a,\reg					; load value
	endif
		ld	(4001h+\part), a			; set value to YM data
    endm

writeYM1		macro reg, value
	writeYMX 0, \_
    endm

writeYM2		macro reg, value
	writeYMX 2, \_
    endm
; ==============================================================================
; ------------------------------------------------------------------------------
; Mute hardware and initialize status
; ------------------------------------------------------------------------------

		di						; disable interrupts
		im	1					; set interrupt mode to 1
		ld	sp,2000h				; load stack address
; ------------------------------------------------------------------------------

		ld	b, 4					; set loop counter to 4
		ld	a, 9Fh					; set volume to max for PSG1

.silencePSG
		ld	(7F11h), a				; write to PSG port
		zadd	a, 20h					; go to next channel
		djnz	.silencePSG				; loop for every channel
; ------------------------------------------------------------------------------

		ld	b, 3					; set loop counter for 3 channels
		ld	c, 0B4h					; FM1 PANNING

.setpanning
		writeYM1 c, 0					; send pan command to port 1
		writeYM2 c, 0					; send pan command to port 2

		inc	c					; go to next channel
		djnz	.setpanning				; loop for all channels
; ------------------------------------------------------------------------------

	; intialize Timer A, max avg load may be 5595 cycles, a fairly safe cycle count is 1.5x that
.timera =	37Ch						; prepare timer A update rate, see calculations below
		writeYM1 24h, .timera>>2			; TIMER A MSB
		writeYM1 25h, .timera&3				; TIMER A LSB

; ms =		18 * (1024 - timera) / 1000			= 2.38
; Hz =		1000 / ms					= 420.88
; upf =		Hz / 60						= 7.01
; cycles =	3579545 / Hz					= 8505
; ------------------------------------------------------------------------------

	; initialize registers
		ld	hl,4000h				; load YM register port to hl
		ld	de,4001h				; load YM data port to de
		ld	a,0
		ld	(MDDC_Queue),a				; set sound queue

	; intialize channels
		ld	bc,MDDC_SndNull				; set a to 0
		ld	(MDDC_FM1+MDDC_cPtr),bc			; set to null routine
		ld	(MDDC_FM2+MDDC_cPtr),bc			;
		ld	(MDDC_FM3+MDDC_cPtr),bc			;

		xor	a					; clear a
		ld	(MDDC_FM1+MDDC_cChannel),a		; save into FM1
		inc	a					; load 1 into a
		ld	(MDDC_FM2+MDDC_cChannel),a		; save into FM2
		inc	a					; load 2 into a
		ld	(MDDC_FM3+MDDC_cChannel),a		; save into FM3
; ==============================================================================
; ------------------------------------------------------------------------------
; Main loop for z80
; ------------------------------------------------------------------------------

MDDC_MainLoop:	; 177
		ld	(hl),27h			; 10	; TIMERS
		ld	a,%00010101			; 7	; prepare value to a
		ld	(de),a				; 7	; send to YM port 1
		exx					; 4	; swap register pairs
; ------------------------------------------------------------------------------

	; handle sound queue
		ld	hl,MDDC_Queue			; 10	; load sound queue pointer to hl
		ld	a,(hl)				; 7	; load the sound queue to a
		ld	(hl),0				; 10	; clear queue
		zor	a				; 4	; decrement queue value
		jpz	MDDC_Trackers			; 10	; branch if underflowed

		ld	hl,MDDC_Sounds-4		; 10	; load sounds array to hl
		zadd	a,a				; 4	; multiply a by 4
		zadd	a,a				; 4	;

		zadd	a,l				; 4	; add low byte to a
		ld	l,a				; 4	; copy back to l
		ld	a,0				; 7	; clear a
		adc	a,h				; 4	; add h and carry to a
		ld	h,a				; 4	; copy back to h

		ld	e,(hl)				; 7	; load channel address to de
		inc	hl				; 6	;
		ld	d,(hl)				; 7	;
		inc	hl				; 6	;
		xor	a				; 4	; clear a

	rept 4
		ld	(de),a				; 7	; clear all volumes
		inc	de				; 6	;
	endr

		inc	de				; 6	; skip channel type
		ld	a,(hl)				; 7	; copy channel tracker address
		ld	(de),a				; 7	;
		inc	de				; 6	;
		inc	hl				; 6	;
		ld	a,(hl)				; 7	;
		ld	(de),a				; 7	;
		inc	de				; 6	;

		ex	de,hl				; 4	; swap channel data to hl
		ld	(hl),0F0h			; 10	; set flags to default
		inc	hl				; 6	;
		ld	(hl),1				; 10	; set initial delay to 1
		inc	hl				; 6	;

		xor	a				; 4	; clear a
		ld	(hl),a				; 7	; clear frequency
		inc	hl				; 6	;
		ld	(hl),a				; 7	;
		inc	hl				; 6	;
		ld	(hl),a				; 7	; clear loop counter
		inc	hl				; 6	;

		ld	de,MDDC_VibVolNull		; 7	; load the null envelope address to de

	rept 3
		ld	(hl),e				; 7	; reset stored vibrato & volume envelopes
		inc	hl				; 6	; and also the current vibrato envelope
		ld	(hl),d				; 7	;
		inc	hl				; 6	;
	endr

	rept 4
		ld	(hl),a				; 7	; clear extra variables
	endr

		ld	(hl),e				; 7	; reset current volume envelope
		inc	hl				; 6	;
		ld	(hl),d				; 7	;
		inc	hl				; 6	;

	rept 4
		ld	(hl),a				; 7	; clear extra variables
	endr
; ------------------------------------------------------------------------------

	; handle trackers
MDDC_Trackers:
		ld	iy,MDDC_FM1			; 24	; load FM1 data to iy
		call	MDDC_Channel			; 1806	; execute channel
		ld	iy,MDDC_FM2			; 24	; load FM2 data to iy
		call	MDDC_Channel			; 1806	; execute channel
		ld	iy,MDDC_FM3			; 24	; load FM3 data to iy
		call	MDDC_Channel			; 1806	; execute channel
; ------------------------------------------------------------------------------

		exx					; 4	; swap register pairs

.wait
	; wait for Timer A
		bit	0,(hl)				; 12	; check if timer a has overflowed
		jpnz	MDDC_MainLoop			; 10	; run again if so
		jp	.wait				; 10	; if not, wait more
; ==============================================================================
; ------------------------------------------------------------------------------
; Table for command pointers
; ------------------------------------------------------------------------------

	cnop 0,$E0
MDDC_CommTable:
		dw MDDC_Vol, MDDC_Vol, MDDC_Vol, MDDC_Vol	; $F0-$F3
		dw MDDC_VolAll					; $F4
		dw MDDC_VolTab					; $F5
		dw MDDC_VibTab					; $F6
		dw MDDC_Voice					; $F7
		dw MDDC_Soft					; $F8
		dw MDDC_Flags					; $F9
		dw 0, 0						; $FA-$FB
		dw MDDC_SpecialPan				; $FC
		dw MDDC_Jump					; $FD
		dw MDDC_Loop					; $FE
		dw MDDC_Stop					; $FF
; ==============================================================================
; ------------------------------------------------------------------------------
; Table for note frequencies
; ------------------------------------------------------------------------------

	cnop 0,$100
MDDC_NoteFreq:
	dw 025Eh,0284h,02ABh,02D3h,02FEh,032Dh,035Ch,038Fh,03C5h,03FFh,043Ch,047Ch
	dw 0A5Eh,0A84h,0AABh,0AD3h,0AFEh,0B2Dh,0B5Ch,0B8Fh,0BC5h,0BFFh,0C3Ch,0C7Ch
	dw 125Eh,1284h,12ABh,12D3h,12FEh,132Dh,135Ch,138Fh,13C5h,13FFh,143Ch,147Ch
	dw 1A5Eh,1A84h,1AABh,1AD3h,1AFEh,1B2Dh,1B5Ch,1B8Fh,1BC5h,1BFFh,1C3Ch,1C7Ch
	dw 225Eh,2284h,22ABh,22D3h,22FEh,232Dh,235Ch,238Fh,23C5h,23FFh,243Ch,247Ch
	dw 2A5Eh,2A84h,2AABh,2AD3h,2AFEh,2B2Dh,2B5Ch,2B8Fh,2BC5h,2BFFh,2C3Ch,2C7Ch
	dw 325Eh,3284h,32ABh,32D3h,32FEh,332Dh,335Ch,338Fh,33C5h,33FFh,343Ch,347Ch
	dw 3A5Eh,3A84h,3AABh,3AD3h,3AFEh,3B2Dh,3B5Ch,3B8Fh,3BC5h,3BFFh,3C3Ch,3C7Ch
; ==============================================================================
; ------------------------------------------------------------------------------
; Table for sounds
; ------------------------------------------------------------------------------

MDDC_Sounds:
.sound		macro pointer, tracker
	dw \pointer, \tracker
    endm

	.sound	MDDC_FM1, MDDC_Reveal_FM1			; $01 - Reveal sound
	.sound	MDDC_FM1, MDDC_Logo_FM1				; $02 - Logo sound
	.sound	MDDC_FM3, MDDC_Lightning_FM23			; $03 - Lightning left
	.sound	MDDC_FM2, MDDC_Lightning_FM23			; $04 - Lightning right
	.sound	MDDC_FM1, MDDC_Cycle_FM1			; $05 - Cycle sound
	.sound	MDDC_FM2, MDDC_Type_FM2				; $06 - Type sound
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine for executing a channel
; ------------------------------------------------------------------------------

MDDC_Channel:	; 35
		dec	(iy+MDDC_cDelay)		; 23	; decrement delay
		jpnz	MDDC_HandleVolume		; 10	; if not 0, skip tracker
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine for executing a tracker
; ------------------------------------------------------------------------------
		; 38
		ld	e,(iy+MDDC_cPtr)		; 19	; load channel address
		ld	d,(iy+MDDC_cPtr+1)		; 19	;

MDDC_Commands:	; 32 or 77
		ld	a,(de)				; 7	; load the next byte
		inc	de				; 6	;
		cp	qCommandFirst			; 7	; check if this is a command
		jrc	.notcommand			; 12/7	; branch if not

		zadd	a,a				; 4	; double a and discard msb
		ld	c,a				; 4	; load a to c
		ld	b,MDDC_CommTable>>8		; 7	; set command table to b

		ld	a,(bc)				; 7	; load low byte to l
		ld	l,a				; 4	;
		inc	bc				; 6	;
		ld	a,(bc)				; 7	; load high byte to h
		ld	h,a				; 4	;
		jp	(hl)				; 7	; jump to instruction
; ------------------------------------------------------------------------------

.notcommand	; 10 or 96
		jpp	.delay				; 10	; if positive, this is short delay

	; load note
		zadd	a,a				; 4	; double offset and ditch msb
		ld	c,a				; 4	; load note offset to c
		ld	b,MDDC_NoteFreq>>8		; 7	; set note frequency table to b

		ld	a,(bc)				; 7	; load frequency low byte to a
		inc	bc				; 6	;
		ld	(iy+MDDC_cFreq),a		; 19	; save to channel
		ld	a,(bc)				; 7	; load frequency high byte to a
		ld	(iy+MDDC_cFreq+1),a		; 19	;

		ld	a,(de)				; 7	; load delay from tracker
		inc	de				; 6	;
; ------------------------------------------------------------------------------

.delay		; 97
		ld	(iy+MDDC_cDelay),a		; 19	; save new delay
		call	MDDC_CommandEnd			; 17	; enable key last
; ------------------------------------------------------------------------------

		exx					; 4	; swap registers
		ld	(hl),28h			; 10	; KEY
		ld	a,(iy+MDDC_cFlags)		; 19	; load flags to a
		zand	0F0h				; 7	; get only key flags
		zor	(iy+MDDC_cChannel)		; 19	; OR channel type
		ld	(de),a				; 7	; send value into data port
		exx					; 4	; swap registers
		ret					; 10
; ------------------------------------------------------------------------------

MDDC_CommandEnd:; 358
		ld	(iy+MDDC_cPtr),e		; 19	; save channel address
		ld	(iy+MDDC_cPtr+1),d		; 19	;

		bit	0,(iy+MDDC_cFlags)		; 20	; check if soft key is on
		jpnz	MDDC_HandleVolume		; 10	; branch if ye

		exx					; 4	; swap registers
		ld	(hl),28h			; 10	; KEY
		ld	a,(iy+MDDC_cChannel)		; 19	; load channel type, all operators off
		ld	(de),a				; 7	; send value into data port
		exx					; 4	; swap registers

		ld	a,(iy+MDDC_cVolStr)		; 19	; copy stored volume pointer to normal
		ld	(iy+MDDC_cVolPtr),a		; 19	;
		ld	a,(iy+MDDC_cVolStr+1)		; 19	; copy stored volume pointer to normal
		ld	(iy+MDDC_cVolPtr+1),a		; 19	;

		ld	a,(iy+MDDC_cVibStr)		; 19	; copy stored vibrato pointer to normal
		ld	(iy+MDDC_cVibPtr),a		; 19	;
		ld	a,(iy+MDDC_cVibStr+1)		; 19	; copy stored vibrato pointer to normal
		ld	(iy+MDDC_cVibPtr+1),a		; 19	;

		xor	a				; 4	; clear a
		ld	(iy+MDDC_cVolPtr+3),a		; 19	; clear variables
		ld	(iy+MDDC_cVolPtr+4),a		; 19	;
		ld	(iy+MDDC_cVolPtr+5),a		; 19	;
		inc	a				; 4	; load 1 to a
		ld	(iy+MDDC_cVolPtr+2),a		; 19	; save as the delay

		xor	a				; 4	; clear a
		ld	(iy+MDDC_cVibPtr+3),a		; 19	; clear variables
		ld	(iy+MDDC_cVibPtr+4),a		; 19	;
		ld	(iy+MDDC_cVibPtr+5),a		; 19	;
		inc	a				; 4	; load 1 to a
		ld	(iy+MDDC_cVibPtr+2),a		; 19	; save as the delay
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine for handling volume
; ------------------------------------------------------------------------------

MDDC_HandleVolume:; 164
		ld	a,iyh				; 8	; load channel high byte to ix
		ld	ixh,a				; 8	;
		ld	a,iyl				; 8	; load channel low byte to a
		zadd	a,MDDC_cVolPtr			; 7	; add volume data offset
		ld	ixl,a				; 8	; load finally to ixl
		call	MDDC_HandlEnv			; 17	; run evenlope processor
		ld	d,a				; 4	; copy offset into d

		push	iy				; 15	; put iy into stack
		pop	hl				; 10	; pop as hl
		ex	af,af				; 4	; store af away

		ld	b,4				; 7	; loop for every volume level
		ld	a,(iy+MDDC_cChannel)		; 19	; load channel id to a
		zadd	a,a				; 4	; double it
		zadd	a,a				; 4	; quadruple it

		exx					; 4	; switch register pairs
		ld	bc,MDDC_TotalLevel		; 10	; load volume register table to bc
		zadd	a,c				; 4	; add offset to c
		ld	c,a				; 4	;

		ld	a,0				; 7	; clear a for the adc
		adc	a,b				; 4	; if there was a carry, add that too
		ld	b,a				; 4	; copy back to b
		exx					; 4	; switch register pairs
; ------------------------------------------------------------------------------

.nextvolume	; 343
		exx					; 4	; switch register pairs
		ld	a,(bc)				; 7	; copy register to a
		inc	bc				; 6	;
		ld	(hl),a				; 7	; load into command port

		exx					; 4	; swap regs
		ld	a,(hl)				; 7	; load value from voice
		inc	hl				; 6	;

		zor	a				; 4	; check if a is negative
		jpp	*+3				; 10	; if not, skip
		zadd	a,d				; 4	; add volume offset

		exx					; 4	; swap regs
		ld	(de),a				; 7	; load value into data port
		exx					; 4	; switch register pairs
		djnz	.nextvolume			; 13/8	; go to next volume
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine for handling vibrato
; ------------------------------------------------------------------------------
		; 293
		ld	a,iyh				; 8	; load channel high byte to ix
		ld	ixh,a				; 8	;
		ld	a,iyl				; 8	; load channel low byte to a
		zadd	a,MDDC_cVibPtr			; 7	; add vibrato data offset
		ld	ixl,a				; 8	; load finally to ixl
		call	MDDC_HandlEnv			; 17	; run evenlope processor

		ld	e,a				; 4	; copy offset into e
		zor	a				; 4	; check if its a negative value
		ld	a,-1				; 7	; set a to -1
		jpm	.neg				; 10	; if was negative, branch
		xor	a				; 4	; set a to 0

.neg
		ld	d,a				; 4	; copy a to d
; ------------------------------------------------------------------------------

		ld	l,(iy+MDDC_cFreq)		; 19	; load frequency to hl
		ld	h,(iy+MDDC_cFreq+1)		; 19	;
		zadd	hl,de				; 11	; add frequency offset to hl

		ld	(iy+MDDC_cFreq),l		; 19	; save frequency back to the channel!
		ld	(iy+MDDC_cFreq+1),h		; 19	;
; ------------------------------------------------------------------------------

		push	hl				; 11	; push into stack
		exx					; 4	; swap register sounds
		pop	bc				; 10	; get it into bc

		ld	a,(iy+MDDC_cChannel)		; 19	; load channel id to a
		zadd	a,0A4h				; 7	; FREQUENCY MSB
		ld	(hl),a				; 7	; load into command port
		ex	af,af				; 4	; swap into af'

		ld	a,b				; 4	; load frequency MSB to a
		ld	(de),a				; 7	; load value into data port

		ex	af,af				; 4	; swap into af
		res	2,a				; 8	; FREQUENCY LSB
		ld	(hl),a				; 7	; load into command port

		ld	a,c				; 4	; load frequency MSB to a
		ld	(de),a				; 7	; load value into data port
		exx					; 4	; switch register pairs
		ret					; 10
; ==============================================================================
; ------------------------------------------------------------------------------
; Stop command
; ------------------------------------------------------------------------------

MDDC_Stop:	; 35
		dec	de				; 6	; go back to the command
		res	0,(iy+MDDC_cFlags)		; 19	; disable soft key
		jp	MDDC_CommandEnd			; 10	; end tracker read
; ==============================================================================
; ------------------------------------------------------------------------------
; Soft key command
; ------------------------------------------------------------------------------

MDDC_Soft:	; 55
		ld	a,(iy+MDDC_cFlags)		; 19	; load flags to a
		xor	1				; 7	; flip soft flag
		ld	(iy+MDDC_cFlags),a		; 19	; save back
		jp	MDDC_Commands			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Set flags command
; ------------------------------------------------------------------------------

MDDC_Flags:	; 42
		ld	a,(de)				; 7	; load the next byte from tracker
		inc	de				; 6	;
		ld	(iy+MDDC_cFlags),a		; 19	; save back
		jp	MDDC_Commands			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Loop command
; ------------------------------------------------------------------------------

MDDC_Loop:	; 96, 93 or 110
		ld	a,(iy+MDDC_cLoop)		; 19	; load current loop counter to a
		zor	a				; 4	; check if 0
		jrz	.is0				; 12/7	; if not, branch
; ------------------------------------------------------------------------------

.not0
		inc	de				; 6	; skip loop counter
		dec	(iy+MDDC_cLoop)			; 23	; decrement loop counter
		jrnz	MDDC_Jump			; 12/7	; if not 0, jump again
		inc	de				; 6	; skip jump pointer
		inc	de				; 6	;
		jp	MDDC_Commands			; 10	; run next command
; ------------------------------------------------------------------------------

.is0
		ld	a,(de)				; 7	; load loop counter into a
		inc	de				; 6	;
		ld	(iy+MDDC_cLoop),a		; 19	; save loop counter
; ==============================================================================
; ------------------------------------------------------------------------------
; Jump command
; ------------------------------------------------------------------------------

MDDC_Jump:	; 96, 93 or 110
		ex	de,hl				; 4	; swap de and hl
		ld	e,(hl)				; 7	; load low byte to e
		inc	hl				; 6	;
		ld	d,(hl)				; 7	; load high byte to d
		jp	MDDC_Commands			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Volume add command
; ------------------------------------------------------------------------------

MDDC_Vol:	; 96
		dec	de				; 6	; back up a little bit
		ld	a,(de)				; 7	; load the command to a
		inc	de				; 6	; and lets a go back
		zand	3				; 7	; get the operator mask

		push	iy				; 15	; put iy into stack
		pop	hl				; 10	; pop as hl
		zadd	a,l				; 4	; add volume offset to hl
		ld	l,a				; 4	;

		ld	a,(de)				; 7	; load volume offset from tracker
		inc	de				; 6	;
		zadd	a,(hl)				; 7	; add channel volume to a
		ld	(hl),a				; 7	; copy volume back to channel
		jp	MDDC_Commands			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Volume add command to every operator
; ------------------------------------------------------------------------------

MDDC_VolAll:	; 148
		ld	a,(de)				; 7	; load volume offset from tracker
		inc	de				; 6	;
		ld	b,a				; 4	; copy to b

		push	iy				; 15	; put iy into stack
		pop	hl				; 10	; pop as hl

	rept 4
		ld	a,(hl)				; 7	; load channel volume to a
		zor	a				; 4	; check if positive
		jpp	*+4				; 10	; branch if yes

		zadd	a,b				; 4	; add volume offset to a
		ld	(hl),a				; 7	; copy volume back to channel
		inc	hl				; 6	; go to next volume level
	endr
		jp	MDDC_Commands			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Volume table load command
; ------------------------------------------------------------------------------

MDDC_VolTab:	; 258
		ld	b,0				; 7	; clear b
		ld	a,(de)				; 7	; load voice id to a
		inc	de				; 6	;
		zadd	a,a				; 4	; double a
		ld	c,a				; 4	; load to c

		ld	hl,MDDC_VolumeTable		; 10	; load volume table to hl
		zadd	hl,bc				; 11	; add offset to the table

		ld	a,(hl)				; 7	; load low byte of table to a
		ld	(iy+MDDC_cVolStr),a		; 19	; save low byte to channel
		inc	hl				; 6	;

		ld	a,(hl)				; 7	; load high byte of table to a
		ld	(iy+MDDC_cVolStr+1),a		; 19	; save high byte to channel
		jp	MDDC_Commands			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Vibrato table load command
; ------------------------------------------------------------------------------

MDDC_VibTab:	; 258
		ld	b,0				; 7	; clear b
		ld	a,(de)				; 7	; load voice id to a
		inc	de				; 6	;
		zadd	a,a				; 4	; double a
		ld	c,a				; 4	; load to c

		ld	hl,MDDC_VibratoTable		; 10	; load vibrato table to hl
		zadd	hl,bc				; 11	; add offset to the table

		ld	a,(hl)				; 7	; load low byte of table to a
		ld	(iy+MDDC_cVibStr),a		; 19	; save low byte to channel
		inc	hl				; 6	;

		ld	a,(hl)				; 7	; load high byte of table to a
		ld	(iy+MDDC_cVibStr+1),a		; 19	; save high byte to channel
		jp	MDDC_Commands			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Special panning for lightning sound
; ------------------------------------------------------------------------------

MDDC_SpecialPan:; 86
		ld	a,(iy+MDDC_cChannel)		; 19	; load channel type to a
		ld	b,a				; 4	; copy a to b temporarily
		ex	af,af				; 4	; swap af with af'

		ld	a,b				; 4	; copy a back
		rrca					; 4	; rotate 2 bits
		rrca					; 4	;
		ex	af,af				; 4	; swap af with af'

		exx					; 4	; switch register pairs
		zadd	a,0B4h				; 7	; add algorith/feedback to channel
		ld	(hl),a				; 7	; load into command port

		ex	af,af				; 4	; swap af with af'
		ld	(de),a				; 7	; load value into data port
		exx					; 4	; switch register pairs
		jp	MDDC_Commands			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Voice load command
; ------------------------------------------------------------------------------

MDDC_Voice:	; 1278
		ld	b,0				; 7	; clear b
		ld	a,(de)				; 7	; load voice id to a
		inc	de				; 6	;
		zadd	a,a				; 4	; double a
		ld	c,a				; 4	; load to c

		ld	hl,MDDC_VoiceTable		; 10	; load voice table to hl
		zadd	hl,bc				; 11	; add offset to the table

		ld	a,(hl)				; 7	; load low byte to a
		inc	hl				; 6	;
		ld	h,(hl)				; 7	; load high byte to h
		ld	l,a				; 4	; copy a to l
; ------------------------------------------------------------------------------

		push	iy				; 15	; put iy into stack
		pop	bc				; 10	; pop as bc

	rept 4
		ld	a,(hl)				; 7	; load voice table to a
		inc	hl				; 6	;
		ld	(bc),a				; 7	; save into channel
		inc	bc				; 6	;
	endr
; ------------------------------------------------------------------------------

		push	hl				; 11	; save into stack
		exx					; 4	; swap register pair
		pop	bc				; 10	; load into bc
		exx					; 4	; swap regs

		ld	a,(iy+MDDC_cChannel)		; 19	; load channel id to a
		ld	b,a				; 4	; copy to b
; ------------------------------------------------------------------------------

.loadreg	macro reg	; 46
	rept narg
		ld	a,b				; 4	; copy channel type to a
		exx					; 4	; swap regs back
		zadd	a,\reg				; 7	; add register to a

		ld	(hl),a				; 7	; load value into command port
		ld	a,(bc)				; 7	; load value from voice
		inc	bc				; 6	;
		ld	(de),a				; 7	; load value into data port
		exx					; 4	; swap regs
	shift
	endr
    endm
; ------------------------------------------------------------------------------

	; write all teh registers to YM
	.loadreg 0B0h, 0B4h				; 92	; algo & feedback & panning
	.loadreg 030h, 034h, 038h, 03Ch			; 184	; detune & multiple
	.loadreg 050h, 054h, 058h, 05Ch			; 184	; ratescale & attackrate
	.loadreg 060h, 064h, 068h, 06Ch			; 184	; sustainrate & ampmod
	.loadreg 070h, 074h, 078h, 07Ch			; 184	; decayrt
	.loadreg 080h, 084h, 088h, 08Ch			; 184	; sustainlv & releasert
		jp	MDDC_Commands			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Total level registers
; ------------------------------------------------------------------------------

MDDC_TotalLevel:
		dc.b 040h, 044h, 048h, 04Ch			; FM1
		dc.b 041h, 045h, 049h, 04Dh			; FM2
		dc.b 042h, 046h, 04Ah, 04Eh			; FM3
; ==============================================================================
; ------------------------------------------------------------------------------
; Routine for handling envelopes
; ------------------------------------------------------------------------------

MDDC_HandlEnv:	; 59 or 191+
		dec	(ix+2)				; 23	; decrement delay
		jrz	.env				; 12/7	; if 0, do envelope
		ld	a,(ix+3)			; 19	; load last value
		ret					; 10
; ------------------------------------------------------------------------------

.env
		ld	e,(ix+0)			; 19	; load low byte to e
		ld	d,(ix+1)			; 19	; load low byte to d

.nextbyte
		ld	a,(de)				; 7	; load next byte
		inc	de				; 6	;

		cp	0FCh				; 7	; check if this is a command
		jrc	.delay				; 12/7	; branch if not
; ------------------------------------------------------------------------------

		zand	3h				; 7	; get command offset
		zadd	a,a				; 4	; double a
		zadd	.commands&$FF			; 7	; add commands table low byte
		ld	c,a				; 4	; copy it to c

		ld	a,0				; 7	; clear a
		adc	.commands>>8			; 7	; add high byte with carry
		ld	b,a				; 4	; copy to b

		ld	a,(bc)				; 7	; load low byte to l
		ld	l,a				; 4	;
		inc	bc				; 6	;
		ld	a,(bc)				; 7	; load high byte to h
		ld	h,a				; 4	;
		jp	(hl)				; 4	; jump to command
; ------------------------------------------------------------------------------

.delay
		ld	(ix+2),a			; 19	; save as delay
		ld	a,(de)				; 7	; load next byte
		zadd	a,(ix+4)			; 19	; add value offset
		ld	(ix+3),a			; 19	; save as value

		inc	de				; 6	;
		ld	(ix+0),e			; 19	; save tracker address
		ld	(ix+1),d			; 19	;
		ret					; 10
; ==============================================================================
; ------------------------------------------------------------------------------
; Envelope commands list
; ------------------------------------------------------------------------------

.commands
		dw .offs					; $FC
		dw .jump					; $FD
		dw .loop					; $FE
		dw .stop					; $FF
; ==============================================================================
; ------------------------------------------------------------------------------
; Envelope command to stop envelope into last entry
; ------------------------------------------------------------------------------

.stop		; 14
		xor	a				; 4	; no offset
		ld	(ix+3),a			; 19	; clear last value
		ret					; 10
; ==============================================================================
; ------------------------------------------------------------------------------
; Envelope command to add to value offset
; ------------------------------------------------------------------------------

.offs		; 61
		ld	a,(de)				; 7	; load offset from envelope
		inc	de				; 6	;
		zadd	a,(ix+4)			; 19	; add previous offset to it
		ld	(ix+4),a			; 19	; save it back as offset
		jp	.nextbyte			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Envelope command to loop envelope
; ------------------------------------------------------------------------------

.loop
		ld	a,(ix+5)			; 19	; load current loop counter to a
		zor	a				; 4	; check if 0
		jrz	.is0				; 12/7	; if yes, branch
; ------------------------------------------------------------------------------

		inc	de				; 6	; skip loop counter
		dec	(ix+5)				; 23	; decrement loop counter
		jrnz	.jump				; 12/7	; if not 0, jump again
		inc	de				; 6	; skip jump pointer
		inc	de				; 6	;
		jp	.nextbyte			; 10	; run next command
; ------------------------------------------------------------------------------

.is0
		ld	a,(de)				; 7	; load loop counter into a
		inc	de				; 6	;
		ld	(ix+5),a			; 19	; save loop counter
; ==============================================================================
; ------------------------------------------------------------------------------
; Envelope command to jump to offset
; ------------------------------------------------------------------------------

.jump
		ex	de,hl				; 4	; swap de and hl
		ld	e,(hl)				; 7	; load low byte to e
		inc	hl				; 6	;
		ld	d,(hl)				; 7	; load high byte to d
		jp	.nextbyte			; 10	; run next command
; ==============================================================================
; ------------------------------------------------------------------------------
; Sound macros
; ------------------------------------------------------------------------------

qCommandFirst =	$F0

; macro to stop channel
qStop		macro
	dc.b $FF
    endm

; macro to loop in a spot for some time
qLoop		macro count, pos
	dc.b $FE, \count-1
	dw \pos
    endm

; macro to jump to a specific spot
qJump		macro pos
	dc.b $FD
	dw \pos
    endm

; macro to jump to add offset to envelope value
qOffset		macro offs
	dc.b $FC, \offs
    endm

; macro for special panning
qSpecPan	macro
	dc.b $FC
    endm

; macro to set channel flags and key mask
qFlags		macro flags
	dc.b $F9, \flags
    endm

; command to disable note-on behavior
qSoft =		$F8

; macro to load a voice into channel
qVoice		macro id
	dc.b $F7, \id
    endm

; macro to set the vibrato table address based on the id
qVibTab		macro id
	dc.b $F6, \id
    endm

; macro to set the volume table address based on the id
qVolTab		macro id
	dc.b $F5, \id
    endm

; macro to change volume for every operator
qVolAll		macro vol
	dc.b $F4, \vol
    endm

; macro to change the channel volume
qVol		macro op, vol
	dc.b $F0+(\op-1), \vol
    endm
; ==============================================================================
; ------------------------------------------------------------------------------
; Note equates
; ------------------------------------------------------------------------------

; this macro is created to emulate enum in AS
enum		macro lable
	rept narg
\lable =	_num
_num =		_num+1
	shift
	endr
    endm

_num =		81h
	enum nC0,nCs0,nD0,nDs0,nE0,nF0,nFs0,nG0,nGs0,nA0,nAs0,nB0	; $8C
	enum nC1,nCs1,nD1,nDs1,nE1,nF1,nFs1,nG1,nGs1,nA1,nAs1,nB1	; $98
	enum nC2,nCs2,nD2,nDs2,nE2,nF2,nFs2,nG2,nGs2,nA2,nAs2,nB2	; $A4
	enum nC3,nCs3,nD3,nDs3,nE3,nF3,nFs3,nG3,nGs3,nA3,nAs3,nB3	; $B0
	enum nC4,nCs4,nD4,nDs4,nE4,nF4,nFs4,nG4,nGs4,nA4,nAs4,nB4	; $BC
	enum nC5,nCs5,nD5,nDs5,nE5,nF5,nFs5,nG5,nGs5,nA5,nAs5,nB5	; $C8
	enum nC6,nCs6,nD6,nDs6,nE6,nF6,nFs6,nG6,nGs6,nA6,nAs6,nB6	; $D4
	enum nC7,nCs7,nD7,nDs7,nE7,nF7,nFs7,nG7,nGs7,nA7,nAs7,nB7	; $E0
; ==============================================================================
; ------------------------------------------------------------------------------
; Lightning sound
; ------------------------------------------------------------------------------

MDDC_Lightning_FM23:
	qVoice		$02
	qSpecPan
	qVibTab		$01
	db nA3, $03, nA2, $03, nGs3, $03, nGs2, $03
	db nG3, $03, nG2, $03, nFs3, $03, nFs2, $03
	db nF3, $03, nF2, $03, nE3, $03, nE2, $03
	db nDs3, $03, nDs2, $03, nD3, $03, nD2, $03
	db nCs3, $03, nCs2, $03, nC3, $03, nC2, $03
	db nB2, $03, nB1, $03, nAs2, $03, nAs1, $03
	qVol		4, -$02

.loop
	qVol		4, $0E
	db nC3, $03, nC2, $03, nB2, $03, nB1, $03
	db nAs2, $03, nAs1, $03, nA2, $03, nA1, $03
	db nGs2, $03, nGs1, $03, nG2, $03, nG1, $03
	db nFs2, $03, nFs1, $03, nF2, $03, nF1, $03
	db nE2, $03, nE1, $03, nDs2, $03, nDs1, $03
	db nD2, $03, nD1, $03, nCs2, $03, nCs1, $03
	qLoop		5, .loop
	qStop
; ==============================================================================
; ------------------------------------------------------------------------------
; Cycle sound
; ------------------------------------------------------------------------------

MDDC_Cycle_FM1:
	qVoice		$00
	qVibTab		$02
	qVolTab		$01

.loop
	rept 2
		db nF3, $60
		qVolAll		$1A
		qVol		2, -$05
		db nFs3, $40
		qVolAll		-$1A
		qVol		2, $05
		qVol		1, $01
	endr
	qVol		2, $01
	qLoop		$07, .loop

	qVibTab		$03
	qVolTab		$02
	db nF3, $B4
	qStop
; ==============================================================================
; ------------------------------------------------------------------------------
; Reveal sound
; ------------------------------------------------------------------------------

MDDC_Reveal_FM1:
	qVoice		$03
	qVibTab		$04
	db nCs2, $0B, nF2, $0B, nB2, $0B, nCs3, $0B
	qVolAll		-$04
	qVol		1, $04

.loop
	db nCs2, $0B, nF2, $0B, nB2, $0B, nCs3, $0B
	qVol		1, $03
	qVolAll		$04
	qLoop		12, .loop

MDDC_SndNull:
	qStop
; ==============================================================================
; ------------------------------------------------------------------------------
; Logo sound
; ------------------------------------------------------------------------------

MDDC_Logo_FM1:
	qVoice		$01
	db nC1, $02, qSoft, nC2, $02, nCs1, $02, nCs2, $02, nD1, $02, nD2, $02, nDs1, $02, nDs2, $02
	db nE1, $02, nE2, $02, nF1, $02, nF2, $02, nFs1, $02, nFs2, $02, nG1, $02, nG2, $02
	db nGs1, $02, nGs2, $02, nA1, $02, nA2, $02, nAs1, $02, nAs2, $02, nB1, $02, nB2, $02
	db nC2, $02, nC3, $02, nCs2, $02, nCs3, $02, nD2, $02, nD3, $02, nDs2, $02, nDs3, $02
	db nE2, $02, nE3, $02, nF2, $02, nF3, $02, nFs2, $02, nFs3, $02, nG2, $02, nG3, $02
	db nGs2, $02, nGs3, $02, nA2, $02, nA3, $02, nAs2, $02, nAs3, $02, nB2, $02, nB3, $02
	db nC3, $02, nC4, $02, nCs3, $02, nCs4, $02, nD3, $02, nD4, $02, nDs3, $02, nDs4, $02
	db nE3, $02, nE4, $02, nF3, $02, nF4, $02, nFs3, $02, nFs4, $02, nG3, $02, nG4, $02
	db nGs3, $02, nGs4, $02, nA3, $02, nA4, $02, nAs3, $02, nAs4, $02, nB3, $02, nB4, $02, qSoft

.loop
	db nC4, $02, qSoft, nC5, $02, nB3, $02, nB4, $02, nAs3, $02, nAs4, $02, nA3, $02, nA4, $02
	db nGs3, $02, nGs4, $02, nG3, $02, nG4, $02, nFs3, $02, nFs4, $02, nF3, $02, nF4, $02
	db nE3, $02, nE4, $02, nDs3, $02, nDs4, $02, nD3, $02, nD4, $02, nCs3, $02, nCs4, $02
	db nC3, $02, nC4, $02, nB2, $02, nB3, $02, nAs2, $02, nAs3, $02, nA2, $02, nA3, $02
	db nGs2, $02, nGs3, $02, nG2, $02, nG3, $02, nFs2, $02, nFs3, $02, nF2, $02, nF3, $02
	db nE2, $02, nE3, $02, nDs2, $02, nDs3, $02, nD2, $02, nD3, $02, nCs2, $02, nCs3, $02, qSoft
	qVol		4, $04
	qLoop		12, .loop
	qStop
; ==============================================================================
; ------------------------------------------------------------------------------
; Typing sound
; ------------------------------------------------------------------------------

MDDC_Type_FM2:
	qVoice		$04

.loop
	db nG0, $06, nE0, $0C, nAs0, $12
	qLoop		4, .loop
	qStop
; ==============================================================================
; ------------------------------------------------------------------------------
; Voice table data
; ------------------------------------------------------------------------------

MDDC_VoiceTable:
		dw MDDC_vCycle					; $00
		dw MDDC_vLogo					; $01
		dw MDDC_vLightning				; $02
		dw MDDC_vReveal					; $03
		dw MDDC_vType					; $04
; ------------------------------------------------------------------------------

MDDC_vCycle:
		db $20, $10, $87, $83				; totallevel
		db $14, $C0					; algo & feedback & panning
		db $15, $12, $03, $11				; detune & multiple
		db $10, $1F, $18, $10				; ratescale & attackrate
		db $10, $16, $0C, $00				; sustainrate & ampmod
		db $02, $02, $02, $02				; decayrt
		db $2F, $2F, $FF, $3F				; sustainlv & releasert

MDDC_vLogo:
		db $20, $26, $20, $83				; totallevel
		db $38, $C0					; algo & feedback & panning
		db $07, $04, $01, $01				; detune & multiple
		db $1F, $1F, $1F, $1F				; ratescale & attackrate
		db $00, $00, $00, $00				; sustainrate & ampmod
		db $00, $00, $00, $00				; decayrt
		db $0F, $0F, $0F, $0F				; sustainlv & releasert

MDDC_vLightning:
		db $14, $04, $08, $83				; totallevel
		db $3B, $C0					; algo & feedback & panning
		db $00, $01, $0A, $02				; detune & multiple
		db $1F, $1F, $1F, $1F				; ratescale & attackrate
		db $00, $00, $00, $00				; sustainrate & ampmod
		db $00, $00, $00, $00				; decayrt
		db $0F, $0F, $0F, $0F				; sustainlv & releasert

MDDC_vReveal:
		db $1A, $92, $8A, $8A				; totallevel
		db $3D, $C0					; algo & feedback & panning
		db $38, $52, $58, $34				; detune & multiple
		db $1F, $1F, $1F, $1F				; ratescale & attackrate
		db $1F, $1F, $1F, $1F				; sustainrate & ampmod
		db $00, $00, $00, $00				; decayrt
		db $0F, $0F, $0F, $0F				; sustainlv & releasert

MDDC_vType:
		db $00, $00, $5B, $80				; totallevel
		db $20, $C0					; algo & feedback & panning
		db $7C, $70, $7F, $7F				; detune & multiple
		db $1F, $1F, $1F, $1F				; ratescale & attackrate
		db $00, $00, $00, $1F				; sustainrate & ampmod
		db $00, $00, $00, $16				; decayrt
		db $F0, $F0, $F0, $0F				; sustainlv & releasert
; ==============================================================================
; ------------------------------------------------------------------------------
; Volume table data
; ------------------------------------------------------------------------------

MDDC_VolumeTable:
		dw MDDC_VibVolNull				; $00
		dw MDDC_VolCycle1				; $01
		dw MDDC_VolCycle2				; $02
; ------------------------------------------------------------------------------

MDDC_VibVolNull:
	db $F0, $00
	qStop

MDDC_VolCycle1:
	db $04, $00, $03, $06
	qJump		MDDC_VolCycle1

MDDC_VolCycle2:
	db $04, $00, $03, $06
	db $04, $00, $03, $06
	qOffset		$01
	qJump		MDDC_VolCycle2
; ==============================================================================
; ------------------------------------------------------------------------------
; Vibrato table data
; ------------------------------------------------------------------------------

MDDC_VibratoTable:
		dw MDDC_VibVolNull				; $00
		dw MDDC_VibLightning1				; $01
		dw MDDC_VibCycle1				; $02
		dw MDDC_VibCycle2				; $03
		dw MDDC_VibReveal				; $05
; ------------------------------------------------------------------------------

MDDC_VibCycle1:
	db $01, -$02
	qLoop		$06, MDDC_VibCycle1
	qOffset		-$01
	qLoop		$08, MDDC_VibCycle1

MDDC_VibCycle2:
	db $08, -$06, $10, $06, $08, -$06
	qOffset		-$02
	qJump		MDDC_VibCycle2

MDDC_VibLightning1:
	db $01, $00, $01, -$80, $01, -$50, $01, $00
	qStop

MDDC_VibReveal:
	db $02, $06, $04, -$06, $02, $06
	qJump		MDDC_VibReveal
; ------------------------------------------------------------------------------
