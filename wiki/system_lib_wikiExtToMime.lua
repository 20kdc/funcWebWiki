-- Extension-to-MIME

local function wikiExtToMime(ext)
	while true do
		local res = wikiReadConfig("system/extensions/mime/" .. ext .. ".txt", nil)
		if res then
			return res
		end
		local idx = ext:find(".", 1, true)
		if not idx then
			return nil
		end
		ext = ext:sub(idx + 1)
	end
end

return wikiExtToMime
