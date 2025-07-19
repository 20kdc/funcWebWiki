-- Default (view) action.
require("system/lib/layer1.lua")
require("system/lib/titlestylize.lua")

wikiLoadTemplate("system/templates/frame")({
	title = wikiTitleStylize(wikiRequestPath),
	path = wikiRequestPath,
	opts = {
		path = "system/templates/recursion",
		opts = {}
	}
})
