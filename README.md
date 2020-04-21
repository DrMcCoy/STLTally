STLTally README
===============

STLTally is a quick and dirty script that calculates and tallies up printing
times and volumes of multiple STLs for use with resin printers. STLTally is
licensed under the terms of the 0-clause BSD license.

It uses and depends on ADMesh, a C library and CLI tool for STL files, to
calculate the volume and read the model height. [ADMesh can be found on GitHub
here.](https://github.com/admesh/admesh)

[STLTally itself can be found on GitHub here.](https://github.com/DrMcCoy/STLTally)

Parameters
----------

While the printing volumes are calculated by ADMesh, the printing times are
calculated using the following parameters, which are the same as the ones set in
ChiTuBox. For quick and dirty reasons, they're defined as variables on the top
of the script; making them command line parameters and/or reading them from a
config file could be a task for the future, if anybody cares.

- layer height in mm
- layer exposure in s
- lifting speed in mm/min
- retraction speed in mm/min
- number of bottom layers
- bottom layer exposure in s
- bottom layer lifting speed in mm/min
- bottom layer retraction speed in mm/min

Real-world
----------

As for real-world comparisons, I found that printing volume estimates are about
10% too low (the loss might be partially explained through resin that clings to
the parts and the build plate). The estimated printing times, however, are about
7% too high, at least on my Qidi Tech Shadow 5.5S. That might be something to
investigate in the future.

Usage
-----

```
stltally.sh <file.stl> [file2.stl] [...]
```

The file that is currently being processed will be written to stderr, the final
results will be printed as a table to stdout.

TODOs
-----

- Set parameters via command line
- Read parameters out of a config file?
- Investigate printing time overestimation
- Deal with volume underestimation (fudge factor?)
- Support more file types?
	- .chitubox (raw meshes like STL)
	- .cbddlp (sliced file)

I'm always happy about ideas, patches, pull requests, etc. Feel free to contact
me via mail or on GitHub.
