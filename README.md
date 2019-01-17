# romBot
Scripts for managing read only memory dumps and binary files from game cartridges/discs for emulation

## cueGen.sh Generate cue file for a directory containing bin files

This script works for PSX binaries. It can be adapted for any kind of cue file by altering the TRACKMODE variable.

Any target directory containing one or more bin files, representing one or more game(s) may be processed by this script. The result will be a cue file for every game contained in the target directory. The directory may also contain other directories which will be processed in the same manner. Directories not containing any bin files will be ignored. Singular bin files will have a cue generated.

To recognize a collection of binary files, belonging to a given game, the files must all have the same name except for the track identification. For example;

> "someRandomGameWithThisName Track01.bin", "someRandomGameWithThisName Track02.bin", ...

Binary files with this name pattern shall be recognized as belonging to a single game and a cue file will be generated for them. Where only a single binary file matches a name pattern found in the target directory, a single track cue file will be generated. 

Valid track identifications conform to this regular expression "(T|t)rack *\d+"

### Usage
Run with ./cueGen.sh <directoryWithBinFiles> [-c] 

Generates cue files for binaries in the given directory. Supports case Where a disc image is spread
over multiple binary files. Supports also folders with many games.

An assumption is made that where an image is spread over multiple binaries, they will have a common 
name excepting the regular pattern '(T|t)rack \d+'

If the -c flag is given, any preexisting cue files will be clobbered
