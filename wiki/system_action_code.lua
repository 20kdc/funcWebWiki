--[[

Similar to <system/action/default> but sets the 'code' flag.

This flag causes <wikiLoadTemplate> to use a level of indirection, i.e. <system/extensions/code/t.lua.txt>

--]]

wikiAST.render(Write, wikiTemplate("system/templates/frame", {
	title = wikiTitleStylize(wikiRequestPath),
	path = wikiRequestPath,
	opts = wikiDefaultOpts,
	code = true
}))
