# funcWebWiki

Personal attempt at trying to make 'the ultimate in-system-customizable wiki'.

No guarantees whatsoever that this is any good. Reports over bugs are very discretionary.

Pull requests and feature requests are probably a little endangered; if a pull request massively refactors everything in a way that cleans up the system and makes everything great, it may be considered; pull requests to the Markdown parser to make it closer to Markdown are the most likely to survive.

[Redbean](https://redbean.dev) 3.0.0 expected.

funcWebWiki is an experiment in trying to provide the ease of installation and deep integrated customization of TiddlyWiki with the ease-of-management and ability to use Git for change-tracking of flat-file wikis.

Almost all of the code that makes up the wiki itself, apart from [Redbean](https://redbean.dev/) and a small 'kernel', is represented as pages in the wiki, such as `system/action/view`.

## Scary Parts

funcWebWiki is not the most robust system, and the markup engine could use some work.

Bolting on a login system should be easy enough but there's no guarantees it'll be 100% secure, safe, etc.

There are probably a _lot_ of scary bottlenecks in the code, particularly around backlinks; the caching system helps but that's made things even scarier.

Stuck link caches are to be expected if updates are made in templates; that kind of thing.

## Licensing

funcWebWiki's License is the Unlicense, good luck and have fun, no warranty etc.

## How To Run It -- out-of-wiki administration

(This section is as opposed to in-wiki administration, which is covered inside the wiki where it can link to the relevant files.)

A funcWebWiki consists of:

* The `wiki/` directory, containing all the mutable contents of the wiki.
* The `kernel/` directory, essentially a 'standard' embeddable Redbean application; really just three files, one of which is a proxy `.init.lua` because that's a hidden file.
* The Redbean server itself.

funcWebWiki was tested with standard Redbean 3.0.0 on Linux; there might be some reason this is important if Redbean doesn't expose some functions in some compile configurations or something. (Shouldn't do, but you never know.)

I would recommend making a checksum of all `system` files in the wiki when you make your personal on-disk fork so you can figure out what you've changed and probably don't want to overwrite if you ever need to do some kind of update.

The wiki can be started in various ways; if you're working with a Git clone of this repository, start with `redbean -D kernel`.

The wiki performs `-l 127.0.0.1` by itself to prevent remote access by default; this can be skipped with `-- --public-unsafe`.

Beware that a writable funcWebWiki has no authentication by default and thus is not safe for public access.

If a standalone single-file release with embedded Redbean is made at some point, then the `-D kernel` option will not be necessary.

It is also possible to embed the `wiki` directory directly into a Redbean server along with the contents of `kernel`; that would look like this:

* `wiki/system_lib_kernel.lua`
* `wiki/` (...the rest of the wiki directory)
* `.args`
* `.init.lua`
* `kernel.lua`

Doing this sets up the wiki in a read-only mode which should not have any persistence; but the code on the wiki is still running.

_Beware: The wiki being read-only in this mode may change at some point. Use `--read-only` if you need to be sure._ (It depends on how cooperative Redbean `StoreAsset` is and if I get around to it.)

Also beware that _in read-only mode, certain caches won't work,_ so if you didn't pre-build the link cache (navigating to `special/missingPages` while mutable should be enough), this can be pretty nasty on CPU.

Finally, there are a number of command-line options; a command such as `redbean -D kernel -- --help` can be used to view them.

## 'Tactical Witch Mode' -- 'oops, I broke it'

The environment variable `WIKI_TWM_PASSWORD` can be set. This enables a special editing mode with `_twm`; `/example?_twm=somePassword` will cause the 'tactical witch mode' editor to be displayed.

If the wiki is deployed in an awkward location and you break something, this can be a way to fix it.

While I wouldn't recommend it, it can also serve as the sole editor.

This functionality is somewhat inspired by LambdaMOO's Emergency Wizard Mode in its similar 'I broke the database; now what?' nature.

Conceivably, you could use this to bootstrap a new wiki on the same kernel; but I wouldn't recommend it.
