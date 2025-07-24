-- Extension-to-MIME, accounting for larger/smaller extensions.

-- Built-in entries that, being statements about MIME types, really don't need dedicated files.
local defaultSet = {
	["css"] = "text/css",
	["html"] = "text/html",
	["ico"] = "image/vnd.microsoft.icon",
	["js"] = "text/javascript",
	["json"] = "text/json",
	["lua"] = "text/lua",
	["md"] = "text/markdown",
	["png"] = "image/png",
	["svg"] = "image/svg+xml",
	["txt"] = "text/plain"
}

return function (path)
	for ext in wikiExtIter(path) do
		local res = wikiReadConfig("system/extensions/mime/" .. ext .. ".txt", defaultSet[ext])
		if res then
			return res
		end
	end
end
