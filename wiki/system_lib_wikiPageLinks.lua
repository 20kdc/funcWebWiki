-- This is where the caching layer would go for page links.
-- Beware: The path given must be resolved, or bad weird things may happen.
return function (path)
	if path:sub(1, 13) == "system/cache/" then
		-- don't even consider this for a cache file
		return {}
	end
	local cachePath = "system/cache/link/" .. path .. ".json"
	local existing = Slurp(cachePath)
	if existing then
		return DecodeJson(existing)
	end
	-- fast-path for missing pages
	if not Slurp(path) then
		return {}
	end
	local rendered = wikiTemplate(path, wikiDefaultOpts)
	local links = {}
	wikiAST.visit(function (node)
		if getmetatable(node) == WikiLink then
			local resolved = wikiResolvePage(node.page)
			links[resolved] = true
		end
	end, rendered)
	Barf(cachePath, EncodeJson(links))
	return links
end
