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
	local memCacheVal = memCache[cachePath]
	if memCacheVal then
		return table.assign({}, memCacheVal)
	end
	-- check to detect changes from Git/etc.
	local contentLength, contentCheck = wikiReadStamp(path)
	-- fast-path: missing pages never have links; don't even try
	if not contentCheck then
		wikiDelete(cachePath)
		return {}
	end
	-- check cache
	local existing = wikiRead(cachePath)
	if existing then
		local dat = DecodeJson(existing)
		-- If the stamp is the empty string, wikiReadStamp is indicating we probably should just trust the cache.
		if dat and ((contentCheck == "") or (dat._check == contentCheck)) then
			-- hide from caller
			dat._check = nil
			memCache[cachePath] = dat
			return table.assign({}, dat)
		end
		-- something went wrong; purge relevant cache to try and fix it
		wikiFlushCacheForPageEdit(path)
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
			-- don't count self-links
			if resolved ~= path then
				links[resolved] = true
			end
		elseif cls == WikiLinkGenIndexMarker then
			isIndex = true
		end
	end, rendered)
	wikiWrite(cachePath, EncodeJson(links))
	if isIndex then
		wikiWrite(indexDummyPath, "1")
	end
	-- hide from caller
	links._check = nil
	memCache[cachePath] = links
	return table.assign({}, links)
end
