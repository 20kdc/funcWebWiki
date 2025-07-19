-- The 'frame' template:
-- * Creates the outer document frame
-- * Provides the action links for the current page.

local opts = ...

local titleEscaped = EscapeHtml(opts.title or "?")

Write("<html><head>\n")
Write("<title>" .. titleEscaped .. "</title>\n")
Write("</head><body>\n")
Write("<h1>" .. titleEscaped .. "</h1>\n")
Write("<ul>")
for k, v in ipairs(wikiPathList("system/action/")) do
	local action = v:sub(15):match("[^.]+")
	Write("<li><a href=\"" .. EscapeHtml(wikiRequestPath) .. "?action=" .. EscapeHtml(action) .. "\">" .. EscapeHtml(action) .. "</a></li>\n")
end
Write("</ul>")
wikiLoadTemplate(opts.path)(opts.opts)
Write("</body></html>")
