-- Reads a single-line configuration textfile.
return function (file, default)
	local value = wikiRead(file) or ""
	value = value:match("[^\r\n]+") or default
	return value
end
