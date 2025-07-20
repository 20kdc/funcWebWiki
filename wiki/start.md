# 'funcWebWiki' - a Redbean-based customizable single-user-wiki system aimed at Git/file backup users

## Introduction

funcWebWiki is intended to provide the ease of installation and deep integrated customization of TiddlyWiki with the ease-of-management and ability to use Git for change-tracking of flat-file wikis.

Almost all of the code that makes up the wiki itself, apart from [Redbean](https://redbean.dev/) and a small 'kernel', is represented as pages in the wiki, such as <system/action/default>.

Global variables inside the wiki always map to respective Lua files; this is to allow for reasonably simple but effective navigation through the code, as so:

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

The 'kernel' provides some level of sandboxing; the rest of the wiki is dynamic without relying on custom languages (outside of a somewhat scuffed version of Markdown).

```t.lua
return h("p", {}, "For example, this paragraph calculates ", 6 * 7, " from 6 * 7.")
```

## Scary Parts

funcWebWiki is not the most robust system, and the markup engine could use some work.

Bolting on a login system should be easy enough but there's no guarantees it'll be 100% secure, safe, etc.

There are probably a _lot_ of scary bottlenecks in the code.

## Installation

A funcWebWiki consists of the `wiki/` directory, the `kernel.lua` file, and the Redbean server. (funcWebWiki was tested with standard Redbean 3.0.0 on Linux; there might be some reason this is important if Redbean doesn't expose some functions in some compile configurations or something. Shouldn't do, but you never know...)

The wiki is started with the following command:

```
redbean -l 127.0.0.1 -F kernel.lua
```

## Things To Explore

* <start?action=z/graphviz> -- DOT file for the whole wiki! (<system/action/z/graphviz> for code.)
* <special/systemPages> contains the full list of system pages.
* <system/templates/frame> is responsible for the 'outer shell'. It displays neatly enough inside the wiki itself.
* <system/lib/kernel> doesn't contain a copy of the kernel, but does describe what role it has, versus the much more tightly-coupled rest of the system.
* <system/extensions/render/md.lua> contains the somewhat cobbled-together semi-Markdown parser.
* <system/extensions/render/lua.lua> contains the code which displays Lua, including mixed Lua/Markdown content.
