# Welcome!

***

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

## Quickstart

Assuming you have a working knowledge of Lua, everything custom about funcWebWiki you absolutely need to know to start writing is contained in the following 'postcard':

```t.lua
return WikiTemplate("special/mdSyntaxCard", {fromStartMD = "the Quickstart"}, false)
```

## How Things Work (Or, Core Concepts)

1. Outside of the 'kernel', _each funcWebWiki request essentially reloads everything._ (See <system/request> if you're curious as to what, exactly, this means.)
2. funcWebWiki uses a 'noun/verb' system, where nouns are pages and verbs are called [actions](system/action). The default verb is <?lua h("code", {}, wikiDefaultAction) ?>.
3. Global scripts intended for maintenance are known as [triggers](system/trigger).
4. [Renderers](system/extensions/render) are responsible for translating markup into the internal [wikiAST](system/lib/wikiAST), which can be examined for link mapping and so forth.
	See file extensions below for how they are matched.
5. The code to create various Lua global functions and variables is stored in <system/lib>.
6. Actions, renderers, and Lua globals (where not from `kernel.lua`) are all pages, and can thus be added and modified by page editing.
	* If you're interested, an index of the code can be found at <special/systemPages>. The assignment of Lua globals allows for in-code hyperlinking.
7. File extensions mean a lot in funcWebWiki. They have two uses:
	* 'Flags'.
		* `.c.` : Reserved for use by the targets of <system/extensions/code> entries for formats like Markdown which render templated by default.
		* `.t.` : Allocated as a flag, but not truly one: `t.` is a prefix to an extension indicating template-versus-code.
			* Where this does get applied more seriously is in <system/lib/wikiRenderer>, which when in `"codeBlock"` mode uses the prefix as an opt-out.
		* `.w.` is used to indicate actions that write (and should not be available on a read-only wiki, where they won't work).
		* `.z.` hides pages from the left navigation sidebar and the top action bar.
	* An extension can also be seen as a series of smaller extensions (see <system/lib/wikiExtIter>). This view is used when a file needs a global 'type'.
		* For example, `.t.lua` is read as the extension `t.lua` (Lua template) and `lua` (Lua code). The largest registered extension wins, so `t.lua` is run.
8. The character `_` is used to emulate directory separators without creating the issues that would result from real directories. Inside the wiki, it is known as `/`.
9. Page titles are stylized for convenience.
	* `system/` pages (considered part of the wiki software itself) are stylized as `~/`.
	* `special/` pages (intended as bookmarks) are stylized as `! `.
10. All pages are also templates that can be included in other pages.
11. Whenever possible, custom languages were avoided.
	* The [funcWebWiki Markdown parser](system/extensions/render/md) has its oddities.
	* Where it was necessary to add metadata, the filenames are used.
	* When a more general-purpose answer was required, Lua was used; for example, this text calculates <?lua 6 * 7?> from 6 * 7.

## Using the Redbean REPL

The Redbean REPL is usable to poke at the funcWebWiki system.

To access the funcWebWiki environment, prefix your table access/etc. with `makeEnv()`.

For instance, `makeEnv().wikiDefaultExt` will return <code >"<?lua tostring(wikiDefaultExt)?>"</code >; if you then edit <system/lib/wikiDefaultExt>, the change will be reflected when you run it again.

## Things To Explore

* <Start?action=graphviz> -- DOT file for the whole wiki! (<system/action/graphviz> for code.)
* <system/index/frame> is responsible for the 'outer shell'. It displays neatly enough inside the wiki itself.
* <system/templates/logo> is the logo.
	Theoretically, it could be anything renderable, but it's been setup to try and match the page top bar.
* <system/request> is the entrypoint for requests; it describes what role the kernel has, versus the much more tightly-coupled rest of the system.
* <system/extensions/render/md> contains the somewhat cobbled-together semi-Markdown parser.
* <system/extensions/render/lua> contains the code which displays Lua, including mixed Lua/Markdown content.

## Modifying funcWebWiki, And Version Compatibility

funcWebWiki is meant to be specifically adapted and customized to your needs by hand.

This 'by-hand' philosophy means it doesn't have much of a plugin system, but it also doesn't have the _architectural complexity_ of a plugin system.

Something I have come to realize is that with how funcWebWiki is setup, _any change worth doing will break something._

With that in mind, the best I can offer is that once a version of funcWebWiki is released, _`kernel.lua` compatibility_ will be maintained as best as reasonably possible with that version.

In other words, that version of the project is expected to work as well as it does on release on any future `funcWebWiki.com` runtime, even if this means wrapping/emulation of Redbean APIs.

By holding to this guarantee, things should be reasonably recoverable.

Even without modifying the `system/` code, the Lua templating allows for adding convenience tools directly to pages, such as:

```t.css
.journal-css-transclude-test {
	padding: 0.5em;
	margin: 0.5em;
	border: 1px solid black;
}
```

```t.lua
-- we would like this link to be *deliberately* invisible to the link scanner
local name = "Journal/" .. os.date("%Y/%m/%d") .. ".z." .. wikiDefaultExt
return h("a", {class="journal-css-transclude-test", href = (wikiAbsoluteBase .. name .. "?action=edit")}, name)
```

## Translating To Your Language

funcWebWiki does not attempt a full translation system. However, room has been left to make sure you _can_ translate it.

Some particular notes:

* System pages are usually 'technically interconnected' and thus shouldn't be internally renamed.
	<system/pageTitle> exists for translation purposes, and it's used for special pages.
* <system/actionName> can be used to translate the visual action names without changing their technical IDs (and breaking everything).
	These and the special page titles make up essentially all of the 'core' UI visible at a glance.
	('raw' is renamed 'download' to test this mechanism without bloating everything.)
* It's variable as to if a message is hard-coded or not, but there are only so many places to look.
