--[[

Maps the entire wiki.

Since this pulls from the template AST, it should be very accurate.

--]]

local function checkFilter(path)
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
		Write("\"n" .. tostring(k) .. "\" [label=\"" .. wikiAST.renderToString(wikiTitleStylize(v), true) .. "\"]\n")
	end
end
for k, v in ipairs(lst) do
	if checkFilter(v) then
		local res = wikiTemplate(v, wikiDefaultOpts)
		local hasLinked = {}
		wikiAST.visit(function (node)
			if getmetatable(node) == WikiLink then
				local pageRes = wikiResolvePage(node.page)
				if not checkFilter(pageRes) then
					return
				end
				if not hasLinked[pageRes] then
					hasLinked[pageRes] = true
					local other = pageRes
					if map[other] then
						other = map[other]
					end
					Write("\"n" .. tostring(k) .. "\" -> \"" .. tostring(other) .. "\"\n")
				end
			end
		end, res)
	end
end
Write("}\n")
