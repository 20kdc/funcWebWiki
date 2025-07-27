System pages make up most of the code of the wiki.

Because there's a _lot_ of them and they aren't relevant except when customizing the wiki, they're not shown in the navigation panel.

Pages which have been changed relative to <system/hashes.json> are marked with `*`; files which have been added are marked with `+`.

If there is a file `system/newHashes.json`, installation assistance is given:

* New files, to install before the rest of the update, are shown at the start of the list.

```t.lua
local t = {}
local systemHashes = DecodeJson(wikiRead("system/hashes.json") or "") or {}
local systemNewHashes = DecodeJson(wikiRead("system/newHashes.json") or "") or {}
local didFind = {}
for _, v in ipairs(wikiPathList("system/")) do
	didFind[v] = true
	-- cache entries are always ignored!
	if v:sub(1, 13) ~= "system/cache/" then
		local styled = WikiLink(v)
		if v ~= "system/hashes.json" and v ~= "system/newHashes.json" then
			local hash = systemHashes[v]
			local hashNew = systemNewHashes[v]
			if hash or hashNew then
				local here = EncodeHex(Md5(wikiRead(v) or ""))
				if hash and hashNew and hash ~= hashNew then
					-- this is a file in both versions and it was updated
					if here == hash then
						styled = {styled, h("b", {}, " (to update)")}
					elseif here == hashNew then
						styled = {styled, " (updated)"}
					else
						styled = {styled, h("b", {}, " (conflict)")}
					end
				elseif here ~= hash then
					styled = {styled, " *"}
				end
			else
				styled = {styled, " +"}
			end
		end
		table.insert(t, h("li", {}, styled))
	end
end
for k, _ in pairs(systemNewHashes) do
	if not didFind[k] then
		local styled = {WikiLink(k), h("b", {}, " (added by update; maybe install before other files)")}
		table.insert(t, 1, h("li", {}, styled))
	end
end
return {
	WikiDepMarker(),
	h("p", {}, "system/"),
	h("ul", {}, t)
}
```
