--[[

The 'frame' template:
 * Creates the outer document frame
 * Provides the action links for the current page.

--]]

local opts = ...

local title = opts.title or "?"

return h("html", {},
	h("head", {},
		h("title", {}, title),
		h("link", {rel="stylesheet", type="text/css", href=(wikiAbsoluteBase .. "system/stylesheet.css?action=raw")})
	),
	h("body", {},
		"\n",
		h("div", {style = "padding-right: 32pt;"},
			wikiLoadTemplate("system/templates/logo")({}),
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
		),
		"\n",
		h("div", {},
			h("h1", {}, title),
			"\n",
			h("ul", {}, function (res)
				for k, v in ipairs(wikiPathList("system/action/")) do
					local action = v:sub(15):match("[^.]+")
					res(h("li", {},
						WikiLink(wikiRequestPath, action, action)
					))
					res("\n")
				end
			end),
			"\n",
			wikiLoadTemplate(opts.path, opts.code)(opts.opts)
		)
	)
)
