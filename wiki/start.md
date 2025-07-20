# 'TemplateWiki' - a Redbean-based customizable single-user-wiki system aimed at Git users

TemplateWiki is intended to provide the ease of installation and deep integrated customization of TiddlyWiki with the managability and ability to use Git for change-tracking of flat-file wikis such as DokuWiki.

Almost all of the code that makes up the wiki itself, apart from a small 'kernel', is represented as pages in the wiki, such as <system/action/default>.

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

TemplateWiki is not the most robust system, and the markup engine could use some work. (As of this writing, the edit button hasn't been implemented; everything else is the 'hard bit', after all...)
