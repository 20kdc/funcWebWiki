System pages make up most of the code of the wiki.

Because there's a _lot_ of them and they aren't relevant except when customizing the wiki, they're not shown in the navigation panel.

```t.lua
return h("ul", {}, function (res)
	local leftBar = wikiPathList("system/")
	local stylizedPlain = {}
	for _, v in ipairs(leftBar) do
		stylizedPlain[v] = wikiTitleStylize(v)
	end
	table.sort(leftBar, function (a, b) return stylizedPlain[a] < stylizedPlain[b] end)
	for _, v in ipairs(leftBar) do
		res(h("li", {},
			WikiLink(v)
		))
		res("\n")
	end
end)
```
