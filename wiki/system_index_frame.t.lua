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

return h("html", {},
	h("head", {},
		h("title", {}, title),
		WikiLink("system/stylesheet.css", {}, "raw", "stylesheet")
	),
	h("body", {},
		"\n",
		h("table", {class = "frame-table"},
			h("tr", {},
				h("td", {class = "frame-logo"},
					WikiTemplate("system/templates/logo")
				),
				h("td", {class = "frame-action-bar"},
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
						res(h("li", {},
							WikiTemplate("system/index/status")
						))
					end)
				)
			),
			h("tr", {},
				h("td", {class = "frame-nav"},
					h("div", {class = "nav-panel"},
						WikiLink(wikiDefaultPage, {
							h("input", {name = "to", value = requestPath}),
							h("input", {type = "submit", value = "Go"})
						}, "z/navigate", "formPost"),
						WikiTemplate("system/templates/sortedPageList", {
							pageList = nonSystemPages
						})
					)
				),
				h("td", {class = "frame-body"},
					h("div", {class = "frame-right-body"},
						WikiTemplate(opts.path, opts.opts, opts.code)
					)
				)
			)
		)
	)
)
