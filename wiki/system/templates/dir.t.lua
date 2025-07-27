-- Used by 'directory heading' pages.
local props = ...

local t = {}
-- if parentPath is nil, no entries will be returned (this is intentional)
local prefix = tostring(props.parentPath or "")
-- the alt-text is used as a quick-and-dirty way to allow for convenient 'remote' directory listings
if props.alt and props.alt ~= "" then
	prefix = tostring(props.alt)
end
prefix = tostring(prefix:match("^[^.]*")) .. "/"
for _, v in ipairs(wikiPathList(prefix)) do
	-- cache entries are always ignored!
	if v:sub(1, 13) ~= "system/cache/" then
		table.insert(t, h("li", {}, WikiLink(v)))
	end
end
return {
	WikiDepMarker(),
	h("p", {}, prefix),
	h("ul", {}, t)
}
