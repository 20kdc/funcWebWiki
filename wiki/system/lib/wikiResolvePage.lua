--[[
This function resolves a 'page path' (can be extension-less) to a 'real' wiki path.

Something to keep in mind is that the `wikiPathParse` rules are that `.` can only be on the last path component (and at least one `.` must be present).

Be careful with when you call this!

Also note the 'default' globals.

Returns the resolved path and the extension.
--]]

return function (wikiPath)
	-- attempt 1: as-is
	local wikiPathParsed, err = wikiPathParse(wikiPath)
	-- attempt 2: default page (expect 'no extension' error)
	if err == "empty" then
		wikiPath = wikiDefaultPage
		wikiPathParsed, err = wikiPathParse(wikiPath)
	end
	-- attempt 3: insert dummy extension for refinement
	local needRefineExtension = false
	if err == "no extension" then
		wikiPath = wikiPath .. ".z"
		wikiPathParsed, err = wikiPathParse(wikiPath)
		needRefineExtension = true
	end
	-- attempt 4: give up
	if not wikiPathParsed then
		return nil, wikiDefaultExt
	end
	-- now that we have parsed it, canonicalize.
	wikiPath = wikiPathUnparse(wikiPathParsed)
	if needRefineExtension then
		-- no extension; find one or make one.
		-- the last two chars are ".z"; make it "." for prefix
		local pfx = wikiPath:sub(1, -2)
		wikiPath = wikiPathList(pfx)[1] or (pfx .. wikiDefaultExt)
		-- reparse as a sanity check
		wikiPathParsed, err = wikiPathParse(wikiPath)
		assert(wikiPathParsed)
	end
	return wikiPath, wikiPath:sub(wikiPath:find(".", 1, true) + 1)
end
