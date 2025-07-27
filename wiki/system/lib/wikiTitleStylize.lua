-- Stylizes titles. This can conceivably return any <system/lib/wikiAST> node.
-- For bug-prevention, this never returns a flat string.

return function (path)
	local idx = path:find(".", 1, true)
	local pathNoExt = path
	if idx then
		pathNoExt = path:sub(1, idx - 1)
	end
	local forced = wikiResolvePage("system/pageTitle/" .. pathNoExt)
	if forced and wikiReadStamp(forced) then
		return WikiTemplate(forced, {inline = true})
	end
	if path:sub(1, 8) == "special/" then
		-- Special pages are pushed to the front of the list.
		return {"! ", pathNoExt:sub(9)}

	end
	if path:sub(1, 7) == "system/" then
		-- System pages are rendered with their extensions.
		return {"~/", path:sub(8)}
	end
	-- Regular pages get / spaced out to look nicer.
	local text = pathNoExt:gsub("/", " / ")
	return {text}
end
