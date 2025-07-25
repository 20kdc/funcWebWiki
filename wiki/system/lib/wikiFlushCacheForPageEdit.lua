-- A page has just been edited or deleted; flush the link cache.
return function (path)
	wikiDelete("system/cache/link/" .. path .. ".json")
	for _, v in ipairs(wikiPathList("system/cache/linkIndex/")) do
		assert(v:sub(1, 23) == "system/cache/linkIndex/")
		assert(v:sub(#v - 3) == ".txt")
		wikiDelete("system/cache/link/" .. v:sub(24, #v - 4) .. ".json")
		wikiDelete(v)
	end
end
