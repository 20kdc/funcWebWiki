-- Extension-to-MIME, accounting for larger/smaller extensions.

-- Built-in entries that, being statements about MIME types, really don't need dedicated files.
local defaultSet = {
	-- text
	["css"] = "text/css",
	["html"] = "text/html",
	["js"] = "text/javascript",
	["json"] = "text/json",
	["lua"] = "text/lua",
	["md"] = "text/markdown",
	["txt"] = "text/plain",
	-- image
	["ico"] = "image/vnd.microsoft.icon",
	["png"] = "image/png",
	["svg"] = "image/svg+xml",
	-- audio
	["wav"] = "audio/vnd.wave",
	["mp3"] = "audio/mpeg",
	["ogg"] = "audio/ogg",
	["opus"] = "audio/ogg",
	-- video
	["mkv"] = "video/matroska",
	["ogv"] = "video/ogg",
	["mp4"] = "video/mp4"
}

return function (path)
	for ext in wikiExtIter(path) do
		local res = wikiReadConfig("system/extensions/mime/" .. ext .. ".txt", defaultSet[ext])
		if res then
			return res
		end
	end
end
