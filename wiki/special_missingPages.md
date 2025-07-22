These pages are referred to, but are ultimately missing.

```t.lua
local lst = wikiPathList()

local exists = {}
for _, v in ipairs(lst) do
	exists[v] = true
end

local missing = {}

local res = {}

for _, v in ipairs(lst) do
	if wikiEnumPageFilter(v) then
		for k, _ in pairs(wikiPageLinks(v)) do
			if (not missing[k]) and not exists[k] then
				missing[k] = true
				table.insert(res, resolved)
			end
		end
	end
end

return {
	WikiLinkGenIndexMarker(),
	WikiTemplate("system/templates/sortedPageList", {
		pageList = res
	})
}
```
