=========================================================================================
	HivePal v2.1
=========================================================================================

HivePal is a palette editor for Sega Mega Drive games, written in Delphi. It can view and
edit palettes in both full ROMs and split disassemblies.

Release Notes For v2.1:
----------------------
* Initial release. Complete rewrite of HivePal v0.3.


=========================================================================================
	Usage
=========================================================================================

 ----------------------------------------------
 |  -----------------------   --------------  |
 | | Load Menu             | |              | |
 |  -----------------------  |              | |
 |  -----------------------  |              | |
 | |                       | | (3)          | |
 | | (1)                   | |              | |
 | |                       | |              | |
 |  -----------------------  |              | |
 |  -----------------------  |              | |
 | | (2)                   | |              | |
 | |                       | |              | |
 |  -----------------------   --------------  |
 |  ----------------------------------------  |
 | | (4)                                    | |
 |  ----------------------------------------  |
 ----------------------------------------------

1. Palette selector. Appears when a palette has been loaded. Select multiple colours by
   click-dragging or right clicking on the second colour you want.

2. Colour menu. Edit the selected colour manually with the RGB bars, or by using the bit
   editor below them. "Advanced Colour Menu" brings up a standard Windows colour menu.
   
3. Palette browser. Displays the entire contents of the ROM or file as a palette. Invalid
   palettes appear grey, but you can override this with "Show Invalid Palettes". Click on
   a colour to load it in the palette selector.

4. ASM editor. Displays the current palette as assembly text. Changes made using the ASM
   editor must be committed by clicking "Update ASM Changes to Palette". This is not
   automatic. You can't change the length of the palette with this. Each line must start
   with "dc.w". Each colour must start with a "$" symbol or it will be interpreted as
   decimal instead of hex.
