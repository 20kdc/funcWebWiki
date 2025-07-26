-- Rebuilds (and optionally flushes) caches.
if GetParam("flush") == "1" then
	-- Log(kLogInfo, "flushing system/cache")
	for _, v in ipairs(wikiPathList("system/cache/")) do
		assert(v:sub(1, 13) == "system/cache/")
		wikiDelete(v)
	end
end
-- Log(kLogInfo, "rebuilding system/cache")
for _, v in ipairs(wikiPathList()) do
	wikiPageLinks(v)
end
