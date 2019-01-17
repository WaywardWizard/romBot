# romBot
Scripts for managing read only memory dumps and binary files from game cartridges/discs for emulation

## cueGen.sh Generate cue file for a directory containing bin files

This script works for PSX binaries. It can be adapted for any kind of cue file by altering the TRACKMODE variable.

Any directory containing one or more bin files belonging to one or more games may be processed by this script. The directory may also contain other directories also containing bin files. Directories not containing any bin files will be ignored. 

To recognize a collection of binary files, belonging to a given game, the files must all have the same name except for the track identification. For example;

> "someRandomGameWithThisName Track01.bin", "someRandomGameWithThisName Track02.bin", ...

Binary files with this name pattern shall be recognized as belonging to a single game and a cue file will be generated for them.

Valid track identifications conform to this regular expression "(T|t)rack *\d+"
