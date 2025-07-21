-- A page has just been edited or deleted; flush the link cache.
return function (path)
	wikiDelete("system/cache/link/" .. path)
	wikiDelete("system/cache/link/system/templates/frame")
	for _, v in ipairs(wikiPathList("special/")) do
		wikiDelete("system/cache/link/" .. v .. ".json")
	end
end
