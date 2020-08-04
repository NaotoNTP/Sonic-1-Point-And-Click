@echo off
"AMPS\Includer.exe" ASM68K AMPS AMPS\.Data
asm68k /m /p /o ae- sonic.asm, s1pointnclick.md, , .lst>.log
type .log
if not exist s1pointnclick.md pause & exit
"AMPS\Dual PCM Compress.exe" AMPS\.z80 AMPS\.z80.dat s1pointnclick.md _dlls\koscmp.exe
error\convsym .lst s1pointnclick.md -input asm68k_lst -inopt "/localSign=. /localJoin=. /ignoreMacroDefs+ /ignoreMacroExp- /addMacrosAsOpcodes+" -a
rompad.exe s1pointnclick.md 255 0
fixheadr.exe s1pointnclick.md
del AMPS\.Data
