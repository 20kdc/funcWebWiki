--[[
This function resolves a 'page path' (can be extension-less) to a 'real' wiki path.

Something to keep in mind is that the `wikiPathParse` rules are that `.` can only be on the last path component (and at least one `.` must be present).

Be careful with when you call this!

Also note the 'default' globals.

Returns the resolved path and the extension.
--]]

-- Since we regularly do full-system lists and have a cache for stuff, let's get it over with.
local resolveCache = {}

for _, v in ipairs(wikiPathList()) do
	local extPoint = v:find(".", 1, true)
	if not extPoint then
		Log(kLogWarn, "kernel.lua is being funny, a file exists without an extension: " .. v)
	else
		local entry = {v, v:sub(extPoint + 1)}
		resolveCache[v] = entry
		local stripped = v:sub(1, extPoint - 1)
		-- only overwrite if not already present (imitates [1] behaviour from before precaching)
		if not resolveCache[stripped] then
			resolveCache[stripped] = entry
		end
	end
end

return function (wikiPath)
	-- early cache skip
	local cached = resolveCache[wikiPath]
	if cached then
		return table.unpack(cached)
	end
	-- attempt 1: as-is
	local wikiPathParsed, err = wikiPathParse(wikiPath)
	-- attempt 2: default page (expect 'no extension' error)
	if err == "empty" then
		wikiPath = wikiDefaultPage
		wikiPathParsed, err = wikiPathParse(wikiPath)
	end
	-- attempt 3: force parse and then add extension later
	local needExtension = false
	if err == "no extension" then
		wikiPathParsed, err = wikiPathParse(wikiPath, true)
		needExtension = true
	end
	-- attempt 4: give up
	if not wikiPathParsed then
		return nil, wikiDefaultExt
	end
	-- now that we have parsed it, canonicalize.
	wikiPath = wikiPathUnparse(wikiPathParsed)
	cached = resolveCache[wikiPath]
	if cached then
		return table.unpack(cached)
	end
	if needExtension then
		-- alright, stick on a default extension
		wikiPath = wikiPath .. "." .. wikiDefaultExt
		return wikiPath, wikiDefaultExt
	end
	-- extract existing extension
	return wikiPath, wikiPath:sub(wikiPath:find(".", 1, true) + 1)
end
