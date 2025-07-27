# funcWebWiki

Personal attempt at trying to make 'the ultimate in-system-customizable wiki'.

No guarantees whatsoever that this is any good. Reports over bugs are very discretionary.

It's an experiment in trying to provide the ease of installation and deep integrated customization of TiddlyWiki with the ease-of-management and ability to use Git for change-tracking of flat-file wikis.

Almost all of the code that makes up the wiki itself, apart from [Redbean](https://redbean.dev) and a small 'kernel', is represented as pages in the wiki, such as `system/action/view`.

Pull requests and feature requests are probably a little endangered; if a pull request massively refactors everything in a way that cleans up the system and makes everything great, it may be considered; pull requests to the Markdown parser to make it closer to Markdown are the most likely to survive.

## How To Run It

* If you want to work with a release, they should come with a copy of [the install guide](./INSTALL_GUIDE.md).
* If you want to work with this Git repository, read the install guide, and _then_ check [the dev guide](./DEV_GUIDE.md).

## Scary Parts

* funcWebWiki is not the most robust system, and the markup engine could use some work.
* Bolting on a login system should be easy enough but there's no guarantees it'll be 100% secure, safe, etc.
	* The `wikiAuthCheck` hook should be present _enough_ to provide a hint but not obtrusive enough to not be easily removed by someone who thinks it's a pain.
* There are probably a _lot_ of scary bottlenecks in the code, particularly around backlinks. The caching system should be reasonably stable now, though.
	* Performance seems to noticably worsen after adding around about 1000 pages. Things can probably be done to improve it, but while preserving the (kind of important) ability to run without a proper database it's a bit of an uphill battle. Profiling needs to be done, also.

## Licensing

[The license of funcWebWiki itself is the Unlicense.](COPYING)

The exceptions to this are releases and the `thirdparty` directory, both of which include Redbean, which has its own series of third-party licenses [from a large part of the Cosmopolitan libc](https://github.com/jart/cosmopolitan/).

The contents of the `thirdparty` directory make a best-effort attempt at license compliance.
