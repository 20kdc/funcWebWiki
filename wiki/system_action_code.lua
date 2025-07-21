--[[

Similar to <system/action/view> but sets the 'code' flag.

This flag causes <system/lib/wikiLoadTemplate> to use a level of indirection; see <system/extensions/code>.

--]]

SetHeader("Content-Type", "text/html")

wikiAST.render(Write, wikiTemplate("system/templates/frame", {
	title = wikiTitleStylize(wikiRequestPath),
	path = wikiRequestPath,
	opts = wikiDefaultOpts,
	code = true
}))
