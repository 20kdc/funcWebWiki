-- This is where the caching layer would go for page links.
-- Beware: The path given must be resolved, or bad weird things may happen.
return function (path)
	if path:sub(1, 13) == "system/cache/" then
		-- don't even consider cache files
		return {}
	end
	local cachePath = "system/cache/link/" .. path .. ".json"
	-- checksum to detect changes from Git/etc.
	local content = Slurp(path)
	local contentCheck = content or ""
	contentCheck = tostring(#contentCheck) .. "|" .. tostring(Crc32(0, contentCheck))
	-- check cache
	local existing = Slurp(cachePath)
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
	local rendered = WikiTemplate(path, wikiDefaultOpts)
	local links = {
		_check = contentCheck
	}
	wikiAST.visit(function (node)
		if getmetatable(node) == WikiLink then
			local resolved = wikiResolvePage(node.page)
			links[resolved] = true
		end
	end, rendered)
	Barf(cachePath, EncodeJson(links))
	-- hide from caller
	links._check = nil
	return links
end
