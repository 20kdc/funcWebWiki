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
local linkType = GetParam("linkType") or "link"
if linkType == "" then
	linkType = "link"
end
for k, v in pairs(map) do
	for pageRes, linkKinds in pairs(wikiPageLinks(k)) do
		if linkKinds[linkType] and map[pageRes] then
			Write("\"" .. v .. "\" -> \"" .. map[pageRes] .. "\"\n")
		end
	end
end
Write("}\n")
