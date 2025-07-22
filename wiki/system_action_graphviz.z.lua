--[[

Maps the entire wiki.

Since this pulls from the template AST, it should be very accurate.

--]]

local function checkFilter(path)
	if path:sub(1, 13) == "system/cache/" then
		return false
	end
	if path:sub(1, 7) == "system/" then
		if GetParam("nosystem") == "1" then
			return false
		end
	end
	if path:sub(1, 8) == "special/" then
		if GetParam("nospecial") == "1" then
			return false
		end
	end
	return true
end

SetHeader("Content-Type", "text/plain")

Write("digraph wiki {\n")
local map = {}
local lst = wikiPathList()
for k, v in ipairs(lst) do
	if checkFilter(v) then
		map[v] = "n" .. tostring(k)
		Write("\"n" .. tostring(k) .. "\" [label=\"" .. wikiAST.renderToString(wikiTitleStylize(v), {renderType = "renderPlain"}) .. "\"]\n")
	end
end
for k, v in pairs(map) do
	for pageRes, _ in pairs(wikiPageLinks(k)) do
		if checkFilter(pageRes) then
			local other = pageRes
			if map[other] then
				other = map[other]
			end
			Write("\"" .. v .. "\" -> \"" .. tostring(other) .. "\"\n")
		end
	end
end
Write("}\n")
