Outside of special pages, these pages have no references, not even on indices like <system/index/frame>.

(While cache data technically counts as pages, it is not included.)

```t.lua
local lst = wikiPathList()

local unreferenced = {}
for _, v in ipairs(lst) do
	-- special pages may still be unreferenced
	if wikiEnumPageFilter(v, true) then
		unreferenced[v] = true
	end
end

for _, v in ipairs(lst) do
	if wikiEnumPageFilter(v) then
		for k, _ in pairs(wikiPageLinks(v)) do
			unreferenced[k] = nil
		end
	end
end

local res = {}

for k, _ in pairs(unreferenced) do
	table.insert(res, k)
end

return {
	WikiLinkGenIndexMarker(),
	WikiTemplate("system/templates/sortedPageList", {
		pageList = res
	})
}
```
