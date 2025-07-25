--[[

The 'frame' template:
 * Creates the outer document frame
 * Provides the action links for the current page.

--]]

local props, renderOptions = ...

local title = props.title or "?"

local nonSystemPages = {}

for _, v in ipairs(wikiPathList()) do
	local visible = true -- Written this way for easier rebasing for downstreams.

	-- Hide hidden pages.
	if v:find(".z.", 1, true) then visible = false end

	-- Hide system pages.
	if v:sub(1, 7) == "system/" then visible = false end

	-- option: Hide special pages when in read-only mode. Not an access restriction, just a UI cleanup.
	-- if wikiReadOnly and v:sub(1, 8) == "special/" then visible = false end

	if visible then
		table.insert(nonSystemPages, v)
	end
end

local requestPath = props.parentPath or props.path or wikiEditorTestPath

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
					WikiTemplate("system/templates/logo", props)
				),
				h("td", {class = "frame-action-bar"},
					h("ul", {class = "action-bar"}, function (res)
						res(h("li", {class = "action-bar-title"}, h("h1", {}, title)))
						if not renderOptions.staticSite then
							for _, v in ipairs(wikiActions) do
								local hidden = v.hidden or (wikiReadOnly and v.mutator) or not wikiAuthCheck(requestPath, v.action)
								if not hidden then
									res(h("li", {class = "action-bar-action"},
										WikiLink(requestPath, WikiTemplate(v.nameTemplate, {inline = true}), v.action)
									))
									res("\n")
								end
							end
						end
						res(h("li", {},
							WikiTemplate("system/index/status", props)
						))
					end)
				)
			),
			h("tr", {},
				h("td", {class = "frame-nav"},
					h("div", {class = "nav-panel"},
						-- <system/action/navigate>
						WikiLink(wikiDefaultPage, {
							h("input", {name = "to", value = requestPath}),
							h("input", {type = "submit", value = "Go"})
						}, "navigate", "formPost"),
						WikiDepMarker(),
						WikiTemplate("system/templates/sortedPageList", {
							pageList = nonSystemPages
						})
					)
				),
				h("td", {class = "frame-body"},
					h("div", {class = "frame-right-body"},
						WikiTemplate(props.path or wikiEditorTestPath, props.props, props.code)
					)
				)
			)
		)
	)
)
