-- "Cleans up" links to be nicer / not include extensions everywhere. This also means permalinks are resistant to changes in extension.
-- Logical inverse to <system/lib//wikiResolvePage>.
return function (v)
	local e = v:find(".", 1, true)
	if e then
		local vs = v:sub(1, e - 1)
		if wikiResolvePage(vs) == v then
			return vs
		end
	end
	return v
end
