-- The 'frame' template:
-- * Creates the outer document frame
-- * Provides the action links for the current page.

local opts = ...

local titleEscaped = EscapeHtml(opts.title or "?")

Write("<html><head>\n")
Write("<title>" .. titleEscaped .. "</title>\n")
Write("</head><body>\n")
Write("<h1>" .. titleEscaped .. "</h1>\n")

local leftBar = wikiPathList()
table.sort(leftBar, function (a, b) return wikiTitleStylize(a) < wikiTitleStylize(b) end)
Write("<ul>")
for k, v in ipairs(leftBar) do
	Write("<li><a href=\"/" .. EscapeHtml(v) .. "\">" .. EscapeHtml(wikiTitleStylize(v)) .. "</a></li>\n")
end
Write("</ul>")

Write("<ul>")
for k, v in ipairs(wikiPathList("system/action/")) do
	local action = v:sub(15):match("[^.]+")
	Write("<li><a href=\"/" .. EscapeHtml(wikiRequestPath) .. "?action=" .. EscapeHtml(action) .. "\">" .. EscapeHtml(action) .. "</a></li>\n")
end
Write("</ul>")
wikiLoadTemplate(opts.path)(opts.opts)
Write("</body></html>")
