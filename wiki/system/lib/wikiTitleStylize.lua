-- Stylizes titles. This can conceivably return any <system/lib/wikiAST> node.
-- For bug-prevention, this never returns a flat string.

local friendlyDirMarker = " / "

return function (path, default)
	local pathNoExt = path
	local idx = pathNoExt:find(".", 1, true)
	if idx then
		pathNoExt = pathNoExt:sub(1, idx - 1)
	end
	local forced = wikiResolvePage("system/pageTitle/" .. pathNoExt)
	if forced and wikiReadStamp(forced) then
		return WikiTemplate(forced, {inline = true})
	end
	if path:sub(1, 8) == "special/" then
		-- Special pages are pushed to the front of the list.
		-- There's assumed to be no directory-stuff going on.
		return {"! ", pathNoExt:sub(9)}

	end
	if path:sub(1, 7) == "system/" then
		-- System pages are rendered with their extensions.
		return {"~/", path:sub(8)}
	end
	-- If there's a specified default, we use it here.
	-- This is used by, i.e. <system/templates/sortedPageList> tree-view.
	if default then
		return {default}
	end
	-- Regular pages have some special handling to make directories, particularly titled ones, work nicely.
	-- For reference purposes: The dogfood instance has `@/SomeName` become `Entities: Some Name`.
	-- The marker is different here; same idea though.
	local rhs = pathNoExt:match("/[^/]*$")
	if rhs then
		-- This is a sub-page. Of what?
		local basis = pathNoExt:sub(1, -(#rhs + 1))
		return {wikiTitleStylize(basis), friendlyDirMarker, rhs:sub(2)}
	else
		return {pathNoExt}
	end
end
