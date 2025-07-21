--[[

Pages referred to but that are missing.

--]]

local lst = wikiPathList()

local exists = {}
for _, v in ipairs(lst) do
	exists[v] = true
end

local missing = {}

local res = {}

for _, v in ipairs(lst) do
	if wikiEnumPageFilter(v) then
		local rendered = wikiTemplate(v, wikiDefaultOpts)
		wikiAST.visit(function (node)
			if getmetatable(node) == WikiLink then
				local resolved = wikiResolvePage(node.page)
				if (not missing[resolved]) and not exists[resolved] then
					missing[resolved] = true
					table.insert(res, resolved)
				end
			end
		end, rendered)
	end
end

return wikiTemplate("system/templates/sortedPageList", {
	pageList = res
})
