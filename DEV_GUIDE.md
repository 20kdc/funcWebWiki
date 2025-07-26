# Developer's Guide

_If you just want to run a quick test patch on the Git repository, `thirdparty/redbean-3.0.0.com -D kernel` will work._

funcWebWiki is built essentially as an image of a 'live system.'

_However,_ for the purposes of a _release,_ there are a number of concerns:

1. Testing.
2. Ensuring updates to `kernel/` are compatible with the first release (the `anchor` tag, if it exists when you're reading this).
3. Running triggers to ensure in-wiki caches aren't stale.
4. Building [APE](https://justine.lol/ape.html) files with everything pre-embedded.

For this, the `fww` shell script is used. (Developers running Windows are advised of <https://github.com/jart/cosmopolitan> and its development environment.)

This shell script's `build` command runs a number of triggers:

1. Flushing and rebuilding the link cache.
2. Sweeping the entire wiki for errors.
3. Updating `system/hashes.json`.

## Release Naming

Release tags are named `rYYMMDD-P`. The following Lua pattern works: `r[0-9][0-9][0-9][0-9][0-9][0-9]%-[a-z]`.

The implication is that funcWebWiki doesn't have a distinct release pattern; it has snapshots.

## Version Compatibility Attempts

The version compatibility goal is that once a version of funcWebWiki is released, the Git branch `anchor` will be created.

* No changes will be made to `anchor`'s kernel, period.
* Tests may be added to `anchor`.
* No changes will be made to `anchor`'s wiki unless there's a _really_ good reason.

The idea is that `anchor` is used as a reference platform to assure some level of compatibility with older wiki versions.

A lot of room has to be left in case of security problems.

But asssuring that a wiki that doesn't use any more functionality than `anchor` will not break provides some level of safety while leaving a lot of flexibility.
