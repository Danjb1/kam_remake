# :european_castle: KaM Remake Mod

A custom version of the open-source [KaM Remake](http://www.kamremake.com/about/).

This is a fork of the [official project](https://github.com/Kromster80/kam_remake) (r6720+), with the changes listed below.

## Changes

 - Trees no longer prevent buildings from being placed

 - Online play disabled (*secure authentication unit is not available for unofficial game clients*)

## Build

Based on the original instructions found [here](https://github.com/reyandme/kam_remake/wiki/ProjectCompilation).

Projects can be compiled using [Delphi](https://www.embarcadero.com/products/delphi/starter).

1. Copy `data` directory from *KaM: TPR* into project folder (don't overwrite).

1. Copy `data/gfx/res/*.rx` to the `SpriteResource` directory.

1. Open the `Utils/RXXPacker/RXXPacker.dpr` project and build.

1. Run `RXXPacker.exe`, select all the available items and press "Pack to RXX File"; this converts all sprites to the required format and puts them in the `data/Sprites` directory.

1. Open `KaM_Remake.dpr` and build.

    > In Delphi, Shift + F9 performs a full build. This can sometimes resolve compilation errors.

## Run

1. Download the [official game](https://www.kamremake.com/download/).

2. Overwrite `KaM_Remake.exe` and `data/Sprites` with the files produced by the build steps, above.

## Debugging

To enable debugging, install [madExcept 5](http://www.madshi.net/madExceptDescription.htm) and edit `KaM_Remake.inc` to remove the dot from the line:

    {.$DEFINE USE_MAD_EXCEPT}
