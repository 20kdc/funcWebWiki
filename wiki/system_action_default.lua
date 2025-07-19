-- Default (view) action.
require("system/lib/layer1.lua")

wikiLoadTemplate("system/templates/frame")({
	title = wikiRequestPath,
	path = wikiRequestPath,
	opts = {}
})
