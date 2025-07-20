-- Stylizes titles.
function wikiTitleStylize(path)
	if path:sub(1, 7) == "system/" then
		return "~/" .. path:sub(8)
	end
	local idx = path:find(".", 1, true)
	if idx then
		return path:sub(1, idx - 1)
	end
	return path
end

-- in-wiki link
WikiLink = {
	renderHtml = function (self, writer)
		local actionSfx = ""
		if self.action ~= "default" then
			actionSfx = "?action=" .. self.action
		end
		writer("<a href=\"" .. EscapeHtml(wikiAbsoluteBase .. self.page .. actionSfx) .. "\">")
		wastRender(writer, self.children, false)
		writer("</a>")
	end,
	renderPlain = function (self, writer)
		wastRender(writer, self.children, true)
	end
}
WikiLink.__index = WikiLink
setmetatable(WikiLink, {__call = function (_, page, children, action)
	return setmetatable({page = tostring(page), children = children or wikiTitleStylize(page), action = tostring(action or "default")}, WikiLink)
end})
