These pages are referred to, but are ultimately missing.

```t.lua
local props, renderOptions = ...

local lst = wikiPathList()

local exists = {}
for _, v in ipairs(lst) do
	exists[v] = true
end

local missing = {}

local res = {}

-- Exempt WikiLink types
local exempt = {
	optLink = true
}

for _, v in ipairs(lst) do
	if wikiEnumPageFilter(v, renderOptions) then
		for k, vtx in pairs(wikiPageLinks(v)) do
			if (not missing[k]) and (not exists[k]) then
				local foundValidLinkType = false
				for linkType, _ in pairs(vtx) do
					if not exempt[linkType] then
						foundValidLinkType = true
						break
					end
				end
				if foundValidLinkType then
					missing[k] = true
					table.insert(res, k)
				end
			end
		end
	end
end

return {
	WikiDepMarker(),
	WikiTemplate("system/templates/sortedPageList", {
		pageList = res
	})
}
```
