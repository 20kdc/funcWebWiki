-- Cleans caches; a.k.a. deletes everything in them.
for _, v in ipairs(wikiPathList("system/cache/")) do
	assert(v:sub(1, 13) == "system/cache/")
	wikiDelete(v)
end
