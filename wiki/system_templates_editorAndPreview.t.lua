local opts = ...

local code = tostring(opts.code or Slurp(tostring(opts.path)) or "")

local leftColumn = wikiTemplate("system/templates/editor", opts)

local rightColumn = nil

local templatePath, templateExt = wikiResolvePage(opts.path)
local renderer = wikiRenderer(templateExt)

rightColumn = renderer(templatePath, code, wikiDefaultOpts)

return h("div", {class = "editor2pane"},
	h("div", {class = "editor2pane-left"}, leftColumn),
	h("div", {class = "editor2pane-right"}, rightColumn)
)
