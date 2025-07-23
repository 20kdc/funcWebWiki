--[[

Maps the entire wiki.

Since this pulls from the template AST, it should be very accurate.

--]]

SetHeader("Content-Type", "text/plain")

Write("digraph wiki {\n")
local map = {}
local lst = wikiPathList()
for k, v in ipairs(lst) do
	if wikiEnumPageFilter(v, { getParam = GetParam }) then
		map[v] = "n" .. tostring(k)
		Write("\"n" .. tostring(k) .. "\" [label=\"" .. wikiAST.renderToString(wikiTitleStylize(v), {renderType = "renderPlain"}) .. "\"]\n")
	end
end
for k, v in pairs(map) do
	for pageRes, _ in pairs(wikiPageLinks(k)) do
		if map[pageRes] then
			Write("\"" .. v .. "\" -> \"" .. map[pageRes] .. "\"\n")
		end
	end
end
Write("}\n")
