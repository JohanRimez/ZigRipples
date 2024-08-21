ZigRipples
Johan Rimez - 2024

This is an open source project featuring:
* ZIG programming language (www.ziglang.org)
* SDL2 - Simple DirectMedia Layer (www.libsdl.org)

This program is intended to demonstrate graphics programming for a simple but fully working coding example using ZIG & SDL.

The original idea for the program came from this coding tutorial:

The Coding Train - Coding challenge #102 - 2D Water Ripple
https://thecodingtrain.com/challenges/102-2d-water-ripple

USAGE:

<any key> quits the application

COMPILING:

The interested coders would immediate find out that the native system wherefor this application is developed, is WindowsOS.
They are invited to adapt the necessary include links (headers & libraries) to their specific installation.
For WindowOS: running the executable works best with the SDL2.dll library in the same directory as the executable.
For Linux: package "libsdl2-dev" should already be installed as a prerequisite.

REMARK:

The main calculation loop is explicitely made without any multiplication to calculate the current pixel index.
No clue whether this is an advantage as the LLVM system clearly optimises at lot in this regard.

Kind regards
Johan*

