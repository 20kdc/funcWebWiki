--[[

The 'frame' template:
 * Creates the outer document frame
 * Provides the action links for the current page.

--]]

local opts = ...

local title = opts.title or "?"

local nonSystemPages = {}

for _, v in ipairs(wikiPathList()) do
	if v:sub(1, 7) ~= "system/" then
		table.insert(nonSystemPages, v)
	end
end

local requestPath = opts.parentPath or opts.path

local frameLeft = {
	h("div", {class = "logo-panel"},
		WikiTemplate("system/templates/logo")
	),
	h("div", {class = "nav-panel"},
		WikiLink(wikiDefaultPage, {
			h("input", {name = "to", value = requestPath}),
			h("input", {type = "submit", value = "Go"})
		}, "z/navigate", "formPost"),
		WikiTemplate("system/templates/sortedPageList", {
			pageList = nonSystemPages
		})
	)
}
local frameRight = {
	h("ul", {class = "action-bar"}, function (res)
		res(h("li", {}, h("h1", {}, title)))
		for k, v in ipairs(wikiPathList("system/action/")) do
			local action = v:sub(15):match("[^.]+")
			if action:sub(1, 2) ~= "z/" then
				res(h("li", {},
					WikiLink(requestPath, action, action)
				))
				res("\n")
			end
		end
	end),
	"\n",
	h("div", {class = "frame-right-body"},
		WikiTemplate(opts.path, opts.opts, opts.code)
	)
}

return h("html", {},
	h("head", {},
		h("title", {}, title),
		WikiLink("system/stylesheet.css", {}, "raw", "stylesheet")
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
