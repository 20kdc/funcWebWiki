-- Special marker component which tells <system/lib/wikiPageLinks> about dependencies.
-- If no dependency path is passed, then this is an _index marker_ (i.e. calls `wikiPathList`) and the cache should be flushed on any edit.
return wikiAST.newClass({
	visit = function ()
	end
}, function (self, depPath)
	local stampLen, stampVal
	if depPath then
		stampLen, stampVal = wikiReadStamp(depPath)
	end
	return setmetatable({
		depPath = depPath,
		depStamp = stampVal
	}, self)
end)
