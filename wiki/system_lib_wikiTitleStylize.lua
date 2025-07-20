-- Stylizes titles. This can conceivably return any <system/lib/wikiAST> node.

return function (path)
	if path:sub(1, 7) == "system/" then
		return "~/" .. path:sub(8)
	end
	local idx = path:find(".", 1, true)
	if idx then
		return path:sub(1, idx - 1)
	end
	return path
end
