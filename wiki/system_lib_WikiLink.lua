-- In-wiki link.
-- Almost all in-wiki links should use this class, as it is used to determine linkage between pages for fancy graphs, missing page detection, etc.

return wikiAST.newClass({
	renderHtml = function (self, writer, renderOptions)
		local actionSfx = ""
		if self.query ~= "" then
			actionSfx = "?" .. self.query
		end
		local href = (renderOptions.absoluteBase or wikiAbsoluteBase) .. wikiExtStripIfClear(self.page) .. actionSfx
		if self.type == "formPost" then
			writer("<form action=\"" .. EscapeHtml(href) .. "\" method=\"post\">\n")
			wikiAST.render(writer, self.children, renderOptions)
			writer("</form>\n")
		elseif self.type == "formGet" then
			writer("<form action=\"" .. EscapeHtml(href) .. "\" method=\"get\">\n")
			wikiAST.render(writer, self.children, renderOptions)
			writer("</form>\n")
		elseif self.type == "stylesheet" then
			writer("<link rel=\"stylesheet\" type=\"text/css\" href=\"" .. EscapeHtml(href) .. "\">\n")
		elseif self.type == "image" then
			local renderOptionsPlain = table.assign({}, renderOptions, {renderType = "renderPlain"})
			writer("<img src=\"" .. EscapeHtml(href) .. "\"")
			local altText = wikiAST.renderToString(self.children, renderOptionsPlain)
			if altText ~= "" then
				writer(" alt=\"" .. EscapeHtml(altText) .. "\"")
			end
			writer(">")
		elseif self.type == "script" then
			writer("<script src=\"" .. EscapeHtml(href) .. "\"></script>")
		else
			writer("<a href=\"" .. EscapeHtml(href) .. "\">")
			wikiAST.render(writer, self.children, renderOptions)
			writer("</a>")
		end
	end,
	renderPlain = function (self, writer, renderOptions)
		wikiAST.render(writer, self.children, renderOptions)
	end
}, function (_, page, children, action, type)
	-- if page contains a query-string, we. if
	local queryAt = page:find("?", 1, true)
	local query = ""
	if queryAt then
		query = page:sub(queryAt + 1)
		page = page:sub(1, queryAt - 1)
	end
	if action then
		query = "action=" .. action
	end
	return setmetatable({page = tostring(page), children = children or wikiTitleStylize(page), query = query, type = (type or "link")}, WikiLink)
end)
