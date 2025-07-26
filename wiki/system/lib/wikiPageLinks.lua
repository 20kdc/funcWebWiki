-- Page link caching layer.
-- Beware: The path given must be resolved, or bad weird things may happen.
local memCache = {}

-- Caches the results of wikiReadStamp. Gives false rather than nil for missing pages.
local stampCache = {}
setmetatable(stampCache, {__index = function (t, k)
	local _, contentCheck = wikiReadStamp(k)
	local res = contentCheck or false
	t[k] = res
	return res
end})

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
	local contentCheck = stampCache[path]
	-- fast-path: missing pages never have links; don't even try
	if not contentCheck then
		wikiDelete(cachePath)
		return {}
	end
	-- check cache
	local existing = wikiRead(cachePath)
	if existing then
		local dat = DecodeJson(existing)
		-- if there's no new-style stamplist, it's not valid (migration from yesterday's funcWebWiki)
		if dat and dat._checks then
			local isValid = true
			for k, v in pairs(dat._checks) do
				local currentStamp = stampCache[k]
				-- If the stamp is the empty string, wikiReadStamp is inoperable; skip further discovery
				if currentStamp == "" then
					break
				end
				-- Otherwise if the stamp differs, a dependency of this page has changed
				if currentStamp ~= v then
					isValid = false
					break
				end
			end
			if isValid then
				-- hide from caller
				dat._checks = nil
				memCache[cachePath] = dat
				return table.assign({}, dat)
			end
		end
		-- something went wrong; purge relevant cache to try and fix it
		wikiFlushCacheForPageEdit(path)
	end

	local newChecks = {}
	-- no matter what, a page is always its own check dependency
	newChecks[path] = contentCheck

	local links = {
		_checks = newChecks
	}
	local isIndex = false

	-- RENDER {
	local rendered = WikiTemplate(path, { linkGen = true })
	local function markLink(toPath, t)
		-- don't count self-links
		if toPath ~= path then
			local a = links[toPath] or {}
			links[toPath] = a
			a[t] = true
		end
	end
	wikiAST.render(function (node)
		local cls = getmetatable(node)
		if cls == WikiLink then
			markLink(node.path, node.type)
		elseif cls == WikiTemplate then
			if type(node.templatePath) == "string" then
				markLink(node.templatePath, "template")
			end
		elseif cls == WikiDepMarker then
			if node.depPath then
				-- This cooperates with stampCache's false-not-nil policy to avoid keys going missing
				newChecks[node.depPath] = node.depStamp or false
			else
				isIndex = true
			end
		end
	end, rendered, { renderType = "visit" })
	-- } RENDER

	wikiWrite(cachePath, EncodeJson(links))
	if isIndex then
		wikiWrite(indexDummyPath, "1")
	end
	-- hide from caller
	links._checks = nil
	memCache[cachePath] = links
	return table.assign({}, links)
end
