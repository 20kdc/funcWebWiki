# Welcome!

If you're reading this, you either looked into the `wiki/` directory, or you have a working **funcWebWiki**. Congratulations!

```t.lua
if wikiReadOnly then
	return {
		h("p", {}, h("b", {}, "Before you continue; your wiki is ", h("i", {}, "read-only!"))),
		h("p", {}, "To make it writable, you need to unzip the ", h("code", {}, "wiki"), " directory from the ", h("code", {}, "funcWebWiki.com"), " file."),
		h("p", {}, "If conventional tools fail, try passing ", h("code", {}, "-- --unpack"), " when launching."),
		h("p", {}, "Your directory structure should look something like this once you're done:"),
		h("ul", {},
			h("li", {},
				"wiki/",
				h("ul", {},
					h("li", {}, "start.md"),
					h("li", {}, "(many more...)")
				)
			),
			h("li", {}, "funcWebWiki.com")
		),
		h("p", {}, "In the meantime, you can explore, but nothing will be editable.")
	}
else
	return {
		h("p", {}, "Before we start; your wiki is writable! That's good. (This message would have changed if it wasn't.)"),
		h("p", {}, "I've tried to keep the amount of 'initial content' pages relatively lean in order to avoid complicating things; you should be able to start writing right away.")
	}
end
```

## How Things Work

The first rule of funcWebWiki is that, outside of the 'kernel', _each funcWebWiki request essentially reloads everything._

See <system/request> if you're curious as to what, exactly, this means; it has details, but also has the entrypoint where requests are handled. APIs are pretty much 'Redbean modulo security concerns'.

funcWebWiki uses a 'noun/verb' system, in a sense.

Files in your `wiki/` directory are available as a wiki page (the 'nouns'), with `_` converted to `/`. Some of those files, aka `system/` (stylized as `~/`) files, are considered part of the wiki software itself. Some of those files, aka `special/` (stylized as `! `) files, are meant to provide 'bookmarks'; where you might otherwise prefix a filename with `AAA` to keep it separated. Other files are content.

On each of these pages, there are different actions (the 'verbs'). By default, the action is `view`.

It's possible to add new pages, but also new actions. The actions also in turn have their own layers of extension mechanisms meant to handle different kinds of file.

If you're interested, an index of the code can be found at <special/systemPages>. This code has hyperlinking, thanks to a particular feature of funcWebWiki:

Global variables inside the wiki always map to respective Lua files in `system/lib` (aka `~/lib`). Global variables must come from these or from the 'funcWebWiki kernel' (aka `kernel.lua`).

Here's an example of some Lua marked up with global references:

```lua
local path, code, opts = ...
-- This example renderer outputs the input text _backwards,_ then wraps it in a template.
-- It might be installed as `system/extensions/render/backwards.lua` - it would then render '.backwards' files.
-- (There are, of course, UTF-8 flaws, and this code is untested. It mainly shows off the hyperlinking.)
local result = ""
for i = 1, #code do
	local ir = #code - (i - 1)
	result = result .. code:sub(ir, ir)
end
return WikiTemplate("exampleBackwardsDisplayTemplate", {
	-- Normally, 'wikiAST.Tag' is written as 'h' (<system/lib/h>), for convenience.
	contents = wikiAST.Tag("p", {}, result)
})
```

The 'kernel' provides some level of sandboxing; the rest of the wiki is dynamic without relying on custom languages (outside of the present limitations of the funcWebWiki Markdown parser).

Still, with what is there, it's possible to run arbitrary Lua code inside a page while not having to write everything in Lua.

```t.lua
return h("p", {}, "For example, this paragraph calculates ", 6 * 7, " from 6 * 7.")
```

## Using the Redbean REPL

The Redbean REPL is usable to poke at the funcWebWiki system.

To access the funcWebWiki environment, prefix your table access/etc. with `makeEnv()`.

```t.lua
return h("p", {}, "For instance, ", h("code", {}, "makeEnv().wikiDefaultExt"), " will return ", h("code", {}, tostring(wikiDefaultExt)), "; if you then edit ", WikiLink("system/lib/wikiDefaultExt"), ", the change will be reflected when you run it again.")
```

## Things To Explore

* <start?action=z/graphviz> -- DOT file for the whole wiki! (<system/action/z/graphviz> for code.)
* <system/index/frame> is responsible for the 'outer shell'. It displays neatly enough inside the wiki itself.
* <system/templates/logo> is the logo.
  Theoretically, it could be anything renderable, but it's been setup to try and match the page top bar.
* <system/request> is the entrypoint for requests; it describes what role the kernel has, versus the much more tightly-coupled rest of the system.
* <system/extensions/render/md> contains the somewhat cobbled-together semi-Markdown parser.
* <system/extensions/render/lua> contains the code which displays Lua, including mixed Lua/Markdown content.

## Modifying funcWebWiki

funcWebWiki is meant to be specifically adapted and customized to your needs by hand.

This 'by-hand' philosophy means it doesn't have much of a plugin system, but it also doesn't have the _architectural complexity_ of a plugin system.

I wrote a functioning version of funcWebWiki in a weekend after bouncing off of TiddlyWiki5 for being too complex and burning out trying to graft what I wanted into TiddlyWiki Classic with a bunch of things going on at once.

(In case anyone was wondering, the particular problem that got me started on this mess basically amounts to a relatively large address book. But without some level of templating, changes to the visual structure had to be propagated, somehow; and easily available portable wiki software just isn't up to that kind of templating, except for TiddlyWiki. Except TiddlyWiki5 involves, simply put, an esoteric internal language, TiddlyWikiClassic can't really save a directory full of files without some 'adaptations,' _and I wouldn't trust either of them to exist in two tabs simultaneously._ My attempt at cutting through the years of legacy cruft to understand what's left well enough to get a-directory-of-files took me a few days, and I ultimately took some of those ideas - in particular my wish for a Smalltalk-esque 'dynamic live system' with as little 'privileged immutable code' as possible - into funcWebWiki.)

While I expect the Markdown parser to take quite a while to perfect, if I get around to it, I think the rest of the system is 'good enough'.

The authentication hook should be present _enough_ to provide a hint but not obtrusive enough to not be easily removed by someone who thinks it's a pain. It should be easy to remove unessential functions like the graphviz exporter via simply deleting their files, and it just works.

Something I would have added if it wouldn't have been too much trouble would be a way to generate a static site from the wiki. I believe it's possible, though.
