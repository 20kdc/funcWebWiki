-- Default (view) action.
require("system/lib/layer1.lua")
require("system/lib/wikilink.lua")

wastRender(Write, wikiLoadTemplate("system/templates/frame")({
	title = wikiTitleStylize(wikiRequestPath),
	path = wikiRequestPath,
	opts = {
		path = "system/templates/recursion",
		opts = {}
	}
}), false)
