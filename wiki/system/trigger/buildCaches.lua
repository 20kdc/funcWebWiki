-- Rebuilds caches. Pairs well with <system/trigger/flushCaches>.
for _, v in ipairs(wikiPathList()) do
	wikiPageLinks(v)
end
