# The Incredible KIMplement: a KIM-1 emulator for the C64

[Another Old VCR Artifact For A New Generation!](http://oldvcr.blogspot.com/)

Copyright 2002-2024 Cameron Kaiser.  
All rights reserved.  
Released under the Floodgap Free Software License.

## What it is

This is the source code for the Incredible KIMplement, an emulator of the [MOS/Commodore KIM-1](http://www.floodgap.com/retrobits/kim-1/) that runs on an unexpanded Commodore 64, or Commodore 128 in 64 mode. It provides a 16K address space, LED and TTY support (including over your C64's _actual_ user port at 300bps), debugging options, and built-in ROMs. It can also load and save memory dumps to disk.

The 6502-on-6502 virtualization is provided by a vendored copy of **6o6**, which is [a separate project](https://github.com/classilla/6o6).

## User manual

For the user manual and downloads, see [the official Incredible KIMplement page](http://www.floodgap.com/retrobits/kim-1/emu.html).

## How to build

This archive builds the KIMplement binary from the provided data files and source code, then assembles the KIMplement emulator (as a raw PRG file), turns the provided example KIM-1 programs into SDAs (self-dissolving archives), and then combines the KIMplement emulator and the example programs into a single compressed `.d64.gz` disk image.

KIMplement is primarily written in 6502 assembly language with the shell written in BASIC. The following utilities and packages are needed to build it:

* `make`
* The [`xa65` cross-assembler](http://www.floodgap.com/retrotech/xa/), at least 2.4.0
* Perl (at least 5.005 or later), which is used for tools to tokenize the BASIC source and link the binary components with the BASIC shell. These tools are in `tools/` and are also under the Floodgap Free Software License.
* [`pucrunch`](http://a1bert.kapsi.fi/Dev/pucrunch/) to compress the resulting binary. If this is missing, the linked `kim.arc` binary is still runnable, just not compressed. The disk image will also not be built.
* `c1541`, part of the [VICE Commodore emulator](https://vice-emu.sourceforge.io/), to create the disk image. If this is missing, you can still use the generated SDAs.

To start the build process, just type `make`. The resulting PRG file is `kim.prg` in the root, as well as copied into `../prg/`, if it exists. The resulting SDAs and `.d64.gz` are in `data/bins/`.

## Issues and pull requests

Issues opened without pull requests may or may not be addressed, in any timeframe. (In particular, don't open issues complaining about the speed. What do you want from a 1MHz C64?) Feature requests opened without pull requests will be closed and/or deleted. Seriously, there's a lot to work on.

## License

The Incredible KIMplement is a derivative work of 6o6 and therefore is also under the Floodgap Free Software License.