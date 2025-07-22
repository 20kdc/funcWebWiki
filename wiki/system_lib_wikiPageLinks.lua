-- Page link caching layer.
-- Beware: The path given must be resolved, or bad weird things may happen.
local memCache = {}
return function (path)
	if path:sub(1, 13) == "system/cache/" then
		-- don't even consider cache files
		return {}
	end
	local cachePath = "system/cache/link/" .. path .. ".json"
	local indexDummyPath = "system/cache/linkIndex/" .. path .. ".txt"
	if memCache[cachePath] then
		return table.assign({}, memCache[cachePath])
	end
	-- checksum to detect changes from Git/etc.
	local content = wikiRead(path)
	local contentCheck = content or ""
	contentCheck = tostring(#contentCheck) .. "|" .. tostring(Crc32(0, contentCheck))
	-- check cache
	local existing = wikiRead(cachePath)
	if existing then
		local dat = DecodeJson(existing)
		if dat and dat._check == contentCheck then
			-- hide from caller
			dat._check = nil
			return dat
		end
		-- something went wrong; purge relevant cache to try and fix it
		wikiFlushCacheForPageEdit(path)
	end
	-- fast-path for missing pages
	if not content then
		return {}
	end

	-- This is a bit hacky, but it prevents <system/lib/wikiEnumPageFilter> callers (special pages) from doing anything stupid.
	-- This is so that they can continue to exist as pages and be indexed.
	local oldGetParam = GetParam
	GetParam = function () return nil end
	local rendered = WikiTemplate(path, table.assign({}, wikiDefaultOpts, { linkGen = true }))
	GetParam = oldGetParam

	local links = {
		_check = contentCheck
	}
	local isIndex = false
	wikiAST.visit(function (node)
		local cls = getmetatable(node)
		if cls == WikiLink then
			local resolved = wikiResolvePage(node.page)
			links[resolved] = true
		elseif cls == WikiLinkGenIndexMarker then
			isIndex = true
		end
	end, rendered)
	memCache[cachePath] = links
	wikiWrite(cachePath, EncodeJson(links))
	if isIndex then
		wikiWrite(indexDummyPath, "1")
	end
	-- hide from caller
	links._check = nil
	return links
end
