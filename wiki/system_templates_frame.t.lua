--[[

The 'frame' template:
 * Creates the outer document frame
 * Provides the action links for the current page.

--]]

local opts = ...

local title = opts.title or "?"

local frameLeft = {
	h("div", {class = "logo-panel"},
		wikiTemplate("system/templates/logo")
	),
	h("div", {class = "nav-panel"},
		WikiLink(wikiRequestPath, {
			h("input", {name = "to", value = wikiRequestPath}),
			h("input", {type = "submit", value = "Go"})
		}, "z/navigate", "formPost"),
		h("ul", {}, function (res)
			local leftBar = wikiPathList()
			local stylizedPlain = {}
			for _, v in ipairs(leftBar) do
				stylizedPlain[v] = wikiTitleStylize(v)
			end
			table.sort(leftBar, function (a, b) return stylizedPlain[a] < stylizedPlain[b] end)
			for _, v in ipairs(leftBar) do
				res(h("li", {},
					WikiLink(v)
				))
				res("\n")
			end
		end)
	)
}
local frameRight = {
	h("ul", {class = "action-bar"}, function (res)
		res(h("li", {}, h("h1", {}, title)))
		for k, v in ipairs(wikiPathList("system/action/")) do
			local action = v:sub(15):match("[^.]+")
			if action:sub(1, 2) ~= "z/" then
				res(h("li", {},
					WikiLink(wikiRequestPath, action, action)
				))
				res("\n")
			end
		end
	end),
	"\n",
	h("div", {class = "frame-right-body"},
		wikiTemplate(opts.path, opts.opts, opts.code)
	)
}

return h("html", {},
	h("head", {},
		h("title", {}, title),
		h("link", {rel="stylesheet", type="text/css", href=(wikiAbsoluteBase .. "system/stylesheet.css?action=raw")})
	),
	h("body", {},
		"\n",
		h("table", {class = "frame-table"},
			h("tr", {},
				h("td", {class = "frame-left"}, frameLeft),
				h("td", {class = "frame-right"}, frameRight)
			)
		)
	)
)
