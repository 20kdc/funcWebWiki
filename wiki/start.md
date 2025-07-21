# Welcome!

If you're reading this, you either looked into the `wiki/` directory, or you have a working funcWebWiki. Congratulations!

I've tried to keep the amount of 'initial content' pages relatively lean in order to avoid complicating things; you should be able to start writing right away.

## How Things Work

The first rule of funcWebWiki is that, outside of 'kernel' changes, _each funcWebWiki request essentially reboots the system._

See <system/lib/kernel> if you're curious as to what, exactly, this means; it has details, but also has the entrypoint where requests are handled. APIs are pretty much 'Redbean modulo security concerns'.

funcWebWiki uses a 'noun/verb' system, in a sense.

Every single file in your `wiki/` directory is available as a wiki page (the 'nouns'), with `_` converted to `/`. Some of those files, aka `system/` (stylized as `~/`) files, are considered part of the wiki software itself. Some of those files, aka `special/` (stylized as `! `) files, are meant to provide 'bookmarks'; where you might otherwise prefix a filename with `AAA` to keep it separated. Other files are content.

On each of these pages, there are different actions (the 'verbs'). By default, the action is `view`.

It's possible to add new pages, but also new actions. The actions also in turn have their own layers of extension mechanisms meant to handle different kinds of file.

If you're interested, an index of the code can be found at <special/systemPages>. This code has hyperlinking, thanks to a particular feature of funcWebWiki:

Global variables inside the wiki always map to respective Lua files in `system/lib` (aka `~/lib`). Global variables must come from these or from the 'funcWebWiki kernel' (aka `kernel.lua`).

Here's an example of some Lua marked up with global references:

```lua
local path, code, opts = ...
-- This example renderer outputs the input text _backwards,_ then wraps it in a template.
-- It might be installed as <system/extensions/render/backwards.lua> - it would then render '.backwards' files.
-- (There are, of course, UTF-8 flaws, and this code is untested. It mainly shows off the hyperlinking.)
local result = ""
for i = 1, #code do
	local ir = #code - (i - 1)
	result = result .. code:sub(ir, ir)
end
return wikiTemplate("exampleBackwardsDisplayTemplate", {
	-- Normally, 'wikiAST.Tag' is written as 'h' (<system/lib/h>), for convenience.
	contents = wikiAST.Tag("p", {}, result)
})
```

The 'kernel' provides some level of sandboxing; the rest of the wiki is dynamic without relying on custom languages (outside of the present limitations of the funcWebWiki Markdown parser).

Still, with what is there, it's possible to run arbitrary Lua code inside a page while not having to write everything in Lua.

```t.lua
return h("p", {}, "For example, this paragraph calculates ", 6 * 7, " from 6 * 7.")
```

## Things To Explore

* <start?action=z/graphviz> -- DOT file for the whole wiki! (<system/action/z/graphviz> for code.)
* <system/templates/frame> is responsible for the 'outer shell'. It displays neatly enough inside the wiki itself.
* <system/lib/kernel> doesn't contain a copy of the kernel, but does describe what role it has, versus the much more tightly-coupled rest of the system.
* <system/extensions/render/md> contains the somewhat cobbled-together semi-Markdown parser.
* <system/extensions/render/lua> contains the code which displays Lua, including mixed Lua/Markdown content.

## Modifying funcWebWiki

funcWebWiki is meant to be specifically adapted and customized to your needs by hand.

This 'by-hand' philosophy means it doesn't have much of a plugin system, but it also doesn't have the _architectural complexity_ of a plugin system.

I wrote a functioning version of funcWebWiki in a weekend after bouncing off of TiddlyWiki5 for being too complex and burning out trying to graft what I wanted into TiddlyWiki Classic with a bunch of things going on at once.

(In case anyone was wondering, the particular problem that got me started on this mess basically amounts to a relatively large address book. But without some level of templating, changes to the visual structure had to be propagated, somehow; and easily available portable wiki software just isn't up to that kind of templating, except for TiddlyWiki. Except TiddlyWiki5 involves, simply put, an esoteric internal language, TiddlyWikiClassic can't really save a directory full of files without some 'adaptations,' _and I wouldn't trust either of them to exist in two tabs simultaneously._ My attempt at cutting through the years of legacy cruft to understand what's left well enough to get a-directory-of-files took me a few days, and I ultimately took some of those ideas - in particular my wish for a Smalltalk-esque 'dynamic live system' with as little 'privileged immutable code' as possible - into funcWebWiki.)

While I expect the Markdown parser to take quite a while to perfect, if I get around to it, I think the rest of the system is 'good enough'.

The authentication hook should be present _enough_ to provide a hint but not obtrusive enough to not be easily removed by someone who thinks it's a pain. It should be easy to remove unessential functions like the graphviz exporter via simply deleting their files, and it just works.

I'm writing this a bit before release, because I want to figure out how to clean up all the implicit references in the graph so that it's clear what _really_ depends on what. I also want a backlinks verb. And a _reasonably_ cheap way to convert to static site. But making the static site thing work is more trouble than its worth, for now.
