-- in-wiki link
local WikiLink = {
	renderHtml = function (self, writer)
		local actionSfx = ""
		if self.action ~= "default" then
			actionSfx = "?action=" .. self.action
		end
		writer("<a href=\"" .. EscapeHtml(wikiAbsoluteBase .. self.page .. actionSfx) .. "\">")
		wikiAST.render(writer, self.children, false)
		writer("</a>")
	end,
	renderPlain = function (self, writer)
		wikiAST.render(writer, self.children, true)
	end
}
WikiLink.__index = WikiLink
setmetatable(WikiLink, {__call = function (_, page, children, action)
	return setmetatable({page = tostring(page), children = children or wikiTitleStylize(page), action = tostring(action or "default")}, WikiLink)
end})
return WikiLink
