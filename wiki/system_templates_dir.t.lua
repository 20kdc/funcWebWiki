-- Used by 'directory heading' pages.
local opts = ...
local t = {}
-- if parentPath is nil, no entries will be returned (this is intentional)
local prefix = tostring(opts.parentPath or "")
prefix = tostring(prefix:match("^[^.]*")) .. "/"
local systemHashes = DecodeJson(wikiRead("system/hashes.json") or "") or {}
for _, v in ipairs(wikiPathList(prefix)) do
	-- cache entries are always ignored!
	if v:sub(1, 13) ~= "system/cache/" then
		local styled = WikiLink(v)
		if v ~= "system/hashes.json" and systemHashes[v] ~= EncodeHex(Md5(wikiRead(v))) then
			styled = {styled, " *"}
		end
		table.insert(t, h("li", {}, styled))
	end
end
return {
	h("p", {}, prefix),
	h("ul", {}, t)
}
