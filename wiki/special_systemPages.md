System pages make up most of the code of the wiki.

Because there's a _lot_ of them and they aren't relevant except when customizing the wiki, they're not shown in the navigation panel.

```t.lua
local systemButNotCache = {}
for _, v in ipairs(wikiPathList("system/")) do
	if v:sub(1, 13) ~= "system/cache/" then
		table.insert(systemButNotCache, v)
	end
end
return wikiTemplate("system/templates/sortedPageList", {pageList = systemButNotCache})
```
