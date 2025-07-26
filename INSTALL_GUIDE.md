# Installation Guide -- For Packaged Releases

_Before we begin,_ if you don't already know some of the potential oddities with APE `.com` files, please see [Cosmopolitan libc documentation](https://justine.lol/cosmopolitan/).

Assuming you have this covered (i.e. you can run `funcWebWiki.com`), continue.

The funcWebWiki you have downloaded comes as a file and a directory:

* `wiki/` : This contains the contents and most of the code of the wiki.
* `funcWebWiki.com` : This is the wiki server, based on the [Redbean](https://redbean.dev) server with some added Lua code to sandbox and run the wiki.

The first thing to note about this setup is that there's a division between Redbean command-line arguments and funcWebWiki command-line arguments. \
When `--` is passed, Redbean command-line arguments go before it; funcWebWiki command-line arguments go after it.

The second thing to note is that the wiki is only accessible to localhost by default to prevent remote access.

This can be skipped with `-- --public-unsafe`, _but writable funcWebWiki has no authentication by default and thus is not safe for public access._

A single global HTTP basic auth `username:password` required for absolutely everything can be set with the environment variable `WIKI_BASIC_AUTH`.

Finally, there are a number of command-line options; a command such as `somewiki.com -- --help` can be used to view them.

## 'Tactical Witch Mode' -- 'oops, I broke it'

The environment variable `WIKI_TWM_PASSWORD` can be set. This enables a special editing mode with `_twm`; `/example?_twm=somePassword` will cause the 'tactical witch mode' editor to be displayed.

If the wiki is deployed in an awkward location and you break something, this can be a way to fix it.

While I wouldn't recommend it, it can also serve as the sole editor.

This functionality is somewhat inspired by LambdaMOO's Emergency Wizard Mode in its similar 'I broke the database; now what?' nature.

Conceivably, you could use this to bootstrap a new wiki on the same kernel; but I wouldn't recommend it.

## Packed Wikis

By zipping the `wiki/` directory into a copy of `funcWebWiki.com`, a "packed wiki" can be created.

Unless this executable sees a `wiki/` directory. it will serve in read-only mode. (_When built with capable Redbean versions, and when the `-*` Redbean option is enabled, a writable wiki is possible, with caveats._)
