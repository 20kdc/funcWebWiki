-- A page has just been edited or deleted; flush the link cache.
return function (path)
	wikiDelete("system/cache/link/" .. path .. ".json")
	-- Notably, it would be nice if some sort of 'template activation marker' remained here.
	-- Chances are, though, this would imply turning <system/lib/wikiTemplate> into an AST component.
	-- And reworking the visitor. But _in theory,_ it'd be really nice.
	for _, v in ipairs(wikiPathList("special/")) do
		wikiDelete("system/cache/link/" .. v .. ".json")
	end
	for _, v in ipairs(wikiPathList("system/index/")) do
		wikiDelete("system/cache/link/" .. v .. ".json")
	end
end
