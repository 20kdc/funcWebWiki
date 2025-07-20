-- Extension-to-MIME, accounting for larger/smaller extensions.
return function (path)
	for ext in wikiExtIter(path) do
		local res = wikiReadConfig("system/extensions/mime/" .. ext .. ".txt", nil)
		if res then
			return res
		end
	end
end