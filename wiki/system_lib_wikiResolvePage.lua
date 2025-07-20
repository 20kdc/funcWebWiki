--[[

This function resolves a 'page path' (can be extension-less) to a 'real' wiki path.

Be careful with when you call this!

Also note the 'default' globals.

Returns the resolved path and the extension.

--]]

return function (wikiPath)
	local wikiPathParsed, err = wikiPathParse(wikiPath)
	if err == "empty" then
		wikiPathParsed = wikiPathParse(wikiDefaultPage)
		assert(wikiPathParsed, "invalid default page")
	end
	wikiPath = wikiPathUnparse(wikiPathParsed)
	-- does the file have an extension?
	local extIdx = wikiPathParsed[#wikiPathParsed]:find(".", 1, true)
	if not extIdx then
		-- no extension; find one or make one
		wikiPath = wikiPathList(wikiPath .. ".")[1] or (wikiPath .. "." .. wikiDefaultExt)
		wikiPathParsed, err = wikiPathParse(wikiPath)
		assert(wikiPathParsed)
		extIdx = wikiPathParsed[#wikiPathParsed]:find(".", 1, true)
		assert(extIdx)
	end
	local ext = wikiPathParsed[#wikiPathParsed]:sub(extIdx + 1)
	return wikiPath, ext
end
