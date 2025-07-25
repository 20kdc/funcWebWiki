# funcWebWiki

Personal attempt at trying to make 'the ultimate in-system-customizable wiki'.

No guarantees whatsoever that this is any good. Reports over bugs are very discretionary.

It's an experiment in trying to provide the ease of installation and deep integrated customization of TiddlyWiki with the ease-of-management and ability to use Git for change-tracking of flat-file wikis.

Almost all of the code that makes up the wiki itself, apart from [Redbean](https://redbean.dev) and a small 'kernel', is represented as pages in the wiki, such as `system/action/view`.

Pull requests and feature requests are probably a little endangered; if a pull request massively refactors everything in a way that cleans up the system and makes everything great, it may be considered; pull requests to the Markdown parser to make it closer to Markdown are the most likely to survive.

## Scary Parts

* funcWebWiki is not the most robust system, and the markup engine could use some work.
* Bolting on a login system should be easy enough but there's no guarantees it'll be 100% secure, safe, etc.
	* The `wikiAuthCheck` hook should be present _enough_ to provide a hint but not obtrusive enough to not be easily removed by someone who thinks it's a pain.
* There are probably a _lot_ of scary bottlenecks in the code, particularly around backlinks. The caching system should be reasonably stable now, though.

## Licensing

[The license of funcWebWiki itself is the Unlicense.](COPYING)

The exceptions to this are releases and the `thirdparty` directory, both of which include Redbean, which has its own series of third-party licenses [from a large part of the Cosmopolitan libc](https://github.com/jart/cosmopolitan/).

The contents of the `thirdparty` directory make a best-effort attempt at license compliance.

## How To Run It -- out-of-wiki administration

(This section is as opposed to in-wiki administration, which is covered inside the wiki where it can link to the relevant files.)

A funcWebWiki consists of:

* The `wiki/` directory, containing all the mutable contents of the wiki.
* The `kernel/` directory, essentially a 'standard' embeddable Redbean application.
* The Redbean server itself.

The kernel and Redbean server can also be bundled together into a single file via the usual Redbean 'embed files with zip' mechanism.

If you aren't managing the `system` directory via Git, be sure to keep in mind the `updateSystemHashes` trigger and the `system/hashes.json` file, as these let you track what parts of the system you've changed.

The wiki can be started in various ways, but they all have this in common: some configurations may need an explicit `ape` loader to launch. See [Cosmopolitan libc documentation](https://justine.lol/cosmopolitan/).

* If you're working with a Git clone of this repository, start with `thirdparty/redbean-3.0.0.com -D kernel`.
	* You can use your own copy of Redbean if you want; Redbean 2.2 is actually required to use mutable packed wikis right now.
* If you're working with a "kernel only" funcWebWiki `.com` file, it can be started directly where the current directory contains a `/wiki` directory.
* If you're working with a wiki packed into a single `.com` file, then like any packed Redbean application it can be run directly.
	* The wiki can be unpacked with `unzip` (also extracts non-content files) or with `somewiki.com -- --unpack` (doesn't do that).
	* If an unpacked wiki is present, it will be preferred over the packed wiki.
	* Packing a wiki can be done by zipping in the contents of the `wiki` directory; the zip should have the paths `/kernel.lua` and `/wiki/system/request.lua` (along with the rest of the kernel & wiki)
	* Packed wikis are writable if the Redbean supports it and is set to allow it.
	* Beware that _in read-only mode, certain caches won't work._ If you didn't pre-build caches (`--trigger buildCaches`) beforehand, features like backlinks can be pretty nasty on CPU.

The wiki performs `-l 127.0.0.1` by itself to prevent remote access by default.

This can be skipped with `-- --public-unsafe`, _but writable funcWebWiki has no authentication by default and thus is not safe for public access._

A single global HTTP basic auth `username:password` required for absolutely everything can be set with the environment variable `WIKI_BASIC_AUTH`.

Finally, there are a number of command-line options; a command such as `somewiki.com -- --help` can be used to view them.

## 'Tactical Witch Mode' -- 'oops, I broke it'

The environment variable `WIKI_TWM_PASSWORD` can be set. This enables a special editing mode with `_twm`; `/example?_twm=somePassword` will cause the 'tactical witch mode' editor to be displayed.

If the wiki is deployed in an awkward location and you break something, this can be a way to fix it.

While I wouldn't recommend it, it can also serve as the sole editor.

This functionality is somewhat inspired by LambdaMOO's Emergency Wizard Mode in its similar 'I broke the database; now what?' nature.

Conceivably, you could use this to bootstrap a new wiki on the same kernel; but I wouldn't recommend it.
