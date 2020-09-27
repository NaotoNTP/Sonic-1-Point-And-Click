@echo off
"Assemble\asm68k" /m /p RAM.asm, RAM.unc, , RAM.lst>RAM.log
type RAM.log
if not exist RAM.unc pause & exit
"Assemble\koscmp" "RAM.unc" "RAM.kos"
pushd "%~dp0\.."
call "build.bat"
move s1pointnclick.md "#MDDC\x.md"
