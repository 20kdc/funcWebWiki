System pages make up most of the code of the wiki.

Because there's a _lot_ of them and they aren't relevant except when customizing the wiki, they're not shown in the navigation panel.

Pages which have been changed relative to <system/hashes.json> are marked with `*`; files which have been added are marked with `+`.

```t.lua
local t = {}
local systemHashes = DecodeJson(wikiRead("system/hashes.json") or "") or {}
for _, v in ipairs(wikiPathList("system/")) do
	-- cache entries are always ignored!
	if v:sub(1, 13) ~= "system/cache/" then
		local styled = WikiLink(v)
		if v ~= "system/hashes.json" then
			local hash = systemHashes[v]
			if not hash then
				styled = {styled, " +"}
			elseif hash ~= EncodeHex(Md5(wikiRead(v))) then
				styled = {styled, " *"}
			end
		end
		table.insert(t, h("li", {}, styled))
	end
end
return {
	WikiDepMarker(),
	h("p", {}, "system/"),
	h("ul", {}, t)
}
```
