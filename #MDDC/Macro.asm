; ==============================================================================
; ------------------------------------------------------------------------------
; Variables and constants for MDDC screen
; ------------------------------------------------------------------------------

MDDC_KosDec equ			KosDec				; kosinski decompression routine
MDDC_EniDec equ			EniDec				; enigma decompression routine
MDDC_ClearScr equ		ClearScreen			; clear screen routine
MDDC_SineTable equ		Sine_Data			; sine data table
MDDC_VintAddr equ		$FFFFFFC6			; vertical interrupt address variable
MDDC_HintCode equ		$FFFFFFCA			; horizontal interrupt code address

MDDC_Start equ			$FFFF2200			; start address of dynamic code block
MDDC_SineTableRef equ		MDDC_Start-4			; sine data table
MDDC_LoadScaleJmp equ		MDDC_Start-$A			; load scale mappings
