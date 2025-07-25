# Developer's Guide

Because funcWebWiki is built essentially as an image of a 'live system,' and `redbean -D kernel` handles the rest, there isn't much of a build step involved in running it.

_However,_ for the purposes of a _release,_ there are a number of concerns:

1. Testing.
2. Ensuring updates to `kernel/` are compatible with the first release (the `anchor` tag, if it exists when you're reading this).
3. Building [APE](https://justine.lol/ape.html) files with everything pre-embedded.

For this, the `fww` shell script is used. (Developers running Windows are advised of <https://github.com/jart/cosmopolitan> and its development environment.)

## Version Compatibility Attempts

The version compatibility goal is that once a version of funcWebWiki is released, the Git branch `anchor` will be created.

* No changes will be made to `anchor`'s kernel, period.
* Tests may be added to `anchor`.
* No changes will be made to `anchor`'s wiki unless there's a _really_ good reason.

The idea is that `anchor` is used as a reference platform to assure some level of compatibility with older wiki versions.

A lot of room has to be left in case of security problems.

But asssuring that a wiki that doesn't use any more functionality than `anchor` will not break provides some level of safety while leaving a lot of flexibility.
