-- A page has just been edited or deleted; flush the link cache.
return function (path)
	wikiDelete("system/cache/link/" .. path .. ".json")
	for _, v in ipairs(wikiPathList("special/")) do
		wikiDelete("system/cache/link/" .. v .. ".json")
	end
	for _, v in ipairs(wikiPathList("system/index/")) do
		wikiDelete("system/cache/link/" .. v .. ".json")
	end
end
