local path, code, opts = ...

local contents = {}

while #code > 0 do
	local startLink = code:find("<", 1, true)
	if startLink then
		table.insert(contents, code:sub(1, startLink - 1))
		code = code:sub(startLink + 1)
		local endLink = code:find(">", 1, true)
		if endLink then
			local href = code:sub(1, endLink - 1)
			code = code:sub(endLink + 1)
			local isExternalLink = href:sub(1, 5) == "http:" or href:sub(1, 6) == "https:"
			if isExternalLink then
				table.insert(contents, h("a", {href = href}, href))
			else
				table.insert(contents, WikiLink(href))
			end
		else
			table.insert(contents, code)
			code = ""
		end
	else
		table.insert(contents, code)
		code = ""
	end
end

return h("pre", {}, contents)
