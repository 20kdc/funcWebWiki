-- Stylizes titles. This can conceivably return any <system/lib/wikiAST> node.
-- For bug-prevention, this always returns a table.

return function (path)
	local pfx = ""
	if path:sub(1, 8) == "special/" then
		-- Special pages are pushed to the front of the list.
		pfx = "! "
		path = path:sub(9)
	end
	if path:sub(1, 7) == "system/" then
		-- System pages are rendered with their extensions.
		return {"~/", path:sub(8)}
	end
	local idx = path:find(".", 1, true)
	if idx then
		return {pfx, path:sub(1, idx - 1)}
	end
	return {pfx, path}
end
