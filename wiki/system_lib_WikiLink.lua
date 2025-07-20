-- in-wiki link
local WikiLink = {
	renderHtml = function (self, writer)
		local actionSfx = ""
		if self.action ~= "default" then
			actionSfx = "?action=" .. self.action
		end
		local href = wikiAbsoluteBase .. self.page .. actionSfx
		if self.type == "formPost" then
			writer("<form action=\"" .. EscapeHtml(href) .. "\" method=\"post\">")
			wikiAST.render(writer, self.children, false)
			writer("</form>")
		else
			writer("<a href=\"" .. EscapeHtml(href) .. "\">")
			wikiAST.render(writer, self.children, false)
			writer("</a>")
		end
	end,
	renderPlain = function (self, writer)
		wikiAST.render(writer, self.children, true)
	end
}
WikiLink.__index = WikiLink
setmetatable(WikiLink, {__call = function (_, page, children, action, type)
	return setmetatable({page = tostring(page), children = children or wikiTitleStylize(page), action = tostring(action or "default"), type = (type or "link")}, WikiLink)
end})
return WikiLink
