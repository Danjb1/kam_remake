# :european_castle: KaM Remake Mod

A custom version of the open-source [KaM Remake](http://www.kamremake.com/about/).

This is a fork of the [official project](https://github.com/Kromster80/kam_remake) (r6720), with the changes listed below.

## Changes

 - Trees no longer prevent buildings from being placed

 - No online play (secure authentication unit is not available for unofficial game clients)

## Build

Based on the original instructions found [here](https://github.com/reyandme/kam_remake/wiki/ProjectCompilation).

Projects can be compiled using [Delphi](https://www.embarcadero.com/products/delphi/starter), or [Lazarus](https://www.lazarus-ide.org/) with [FPC 3.0.0](https://sourceforge.net/projects/freepascal/files/Win32/3.0.0/).

1. Copy `data` directory from *KaM: TPR* into project folder (don't overwrite).

1. Copy `data/gfx/res/*.rx` to the `SpriteResource` directory.

1. Open the `Utils/RXXPacker/RXXPacker.dpr` project and build.

1. Run `RXXPacker.exe`, select all the available items and press "Pack to RXX File"; this converts all sprites to the required format and puts them in the `data/Sprites` directory.

1. Open `KaM_Remake.dpr` and build.

    > In Delphi, Shift + F9 performs a full build. This can sometimes resolve compilation errors.

## Debugging

To enable debugging, install [madExcept 5](http://www.madshi.net/madExceptDescription.htm) and edit `KaM_Remake.inc` to remove the dot from the line:

    {.$DEFINE USE_MAD_EXCEPT}
