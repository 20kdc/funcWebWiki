--[[

The 'frame' template:
 * Creates the outer document frame
 * Provides the action links for the current page.

--]]

local props, renderOptions = ...

local title = props.title or "?"

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
						WikiTemplate("system/index/navPanel", props)
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
