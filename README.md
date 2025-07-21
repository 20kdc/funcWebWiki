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

## How To Run It

A funcWebWiki consists of the `wiki/` directory, the `kernel.lua` file, and the Redbean server. (funcWebWiki was tested with standard Redbean 3.0.0 on Linux; there might be some reason this is important if Redbean doesn't expose some functions in some compile configurations or something. Shouldn't do, but you never know...)

I would recommend making a checksum of all `system` files in the wiki when you make your personal on-disk fork so you can figure out what you've changed and probably don't want to overwrite if this ever somehow gets a second version that people actually specifically want to upgrade to.

The wiki is started with the following command:

```
redbean -l 127.0.0.1 -F kernel.lua
```
