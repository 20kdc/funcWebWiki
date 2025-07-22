# funcWebWiki

Personal attempt at trying to make 'the ultimate in-system-customizable wiki'.

No guarantees whatsoever that this is any good. Reports over bugs are very discretionary.

It's an experiment in trying to provide the ease of installation and deep integrated customization of TiddlyWiki with the ease-of-management and ability to use Git for change-tracking of flat-file wikis.

Almost all of the code that makes up the wiki itself, apart from [Redbean](https://redbean.dev) and a small 'kernel', is represented as pages in the wiki, such as `system/action/view`.

Pull requests and feature requests are probably a little endangered; if a pull request massively refactors everything in a way that cleans up the system and makes everything great, it may be considered; pull requests to the Markdown parser to make it closer to Markdown are the most likely to survive.

## Scary Parts

funcWebWiki is not the most robust system, and the markup engine could use some work.

Bolting on a login system should be easy enough but there's no guarantees it'll be 100% secure, safe, etc.

There are probably a _lot_ of scary bottlenecks in the code, particularly around backlinks; the caching system helps but that's made things even scarier.

Stuck link caches are to be expected if updates are made in templates; that kind of thing.

## Licensing

[The license of funcWebWiki itself is the Unlicense.](COPYING)

The exceptions to this are releases and the `thirdparty` directory, both of which include Redbean, which has its own series of third-party licenses [from a large part of the Cosmopolitan libc](https://github.com/jart/cosmopolitan/).

The contents of the `thirdparty` are a best-effort attempt at license compliance.

## How To Run It -- out-of-wiki administration

(This section is as opposed to in-wiki administration, which is covered inside the wiki where it can link to the relevant files.)

A funcWebWiki consists of:

* The `wiki/` directory, containing all the mutable contents of the wiki.
* The `kernel/` directory, essentially a 'standard' embeddable Redbean application; really just three files, one of which is a proxy `.init.lua` because that's a hidden file.
* The Redbean server itself.

The kernel and Redbean server can also be bundled together into a single file via the usual Redbean 'embed files with zip' mechanism.

I would recommend making a checksum of all `system` files in the wiki when you make your personal on-disk fork so you can figure out what you've changed (and what you probably don't want to overwrite if you ever need to do some kind of update).

The wiki can be started in various ways, but they all have this in common: some configurations may need an explicit `ape` loader to launch. See [Cosmopolitan libc documentation](https://justine.lol/cosmopolitan/).

* If you're working with a Git clone of this repository, start with `thirdparty/redbean-3.0.0.com -D kernel`.
	* You can use your own copy of Redbean if you want, though funcWebWiki has only been tested on this specific Redbean version.)
* If you're working with a "kernel only" funcWebWiki `.com` file, it can be started directly where the current directory contains a `/wiki` directory.
* If you're working with a read-only wiki packed into a single `.com` file, then like any packed Redbean application it can be run directly.
	* The wiki can be unpacked with `unzip` (also extracts non-content files) or with `somewiki.com -- --unpack` (doesn't do that).
	* If an unpacked wiki is present, it will be preferred over the built-in wiki.
	* Packing a wiki can be done by zipping in the contents of the `wiki` directory; the zip should have the paths `/kernel.lua` and `/wiki/system_lib_kernel.lua`.

The wiki performs `-l 127.0.0.1` by itself to prevent remote access by default; this can be skipped with `-- --public-unsafe`.

_Beware that a writable funcWebWiki has no authentication by default and thus is not safe for public access._

Doing this sets up the wiki in a read-only mode which should not have any persistence; but the code on the wiki is still running.

_Beware: The wiki being read-only in this mode may change at some point. Use `--read-only` if you need to be sure._ (It depends on how cooperative Redbean `StoreAsset` is and if I get around to it.)

Also beware that _in read-only mode, certain caches won't work,_ so if you didn't pre-build caches (`--trigger buildCaches`) beforehand, this can be pretty nasty on CPU.

Finally, there are a number of command-line options; a command such as `somewiki.com -- --help` can be used to view them.

## 'Tactical Witch Mode' -- 'oops, I broke it'

The environment variable `WIKI_TWM_PASSWORD` can be set. This enables a special editing mode with `_twm`; `/example?_twm=somePassword` will cause the 'tactical witch mode' editor to be displayed.

If the wiki is deployed in an awkward location and you break something, this can be a way to fix it.

While I wouldn't recommend it, it can also serve as the sole editor.

This functionality is somewhat inspired by LambdaMOO's Emergency Wizard Mode in its similar 'I broke the database; now what?' nature.

Conceivably, you could use this to bootstrap a new wiki on the same kernel; but I wouldn't recommend it.
