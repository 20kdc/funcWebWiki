-- Used by 'directory heading' pages.
local opts = ...
local t = {}
-- if parentPath is nil, no entries will be returned (this is intentional)
local prefix = tostring(opts.parentPath or "")
prefix = tostring(prefix:match("^[^.]*")) .. "/"
for _, v in ipairs(wikiPathList(prefix)) do
	table.insert(t, h("li", {}, WikiLink(v)))
end
return {
	h("p", {}, prefix),
	h("ul", {}, t)
}
