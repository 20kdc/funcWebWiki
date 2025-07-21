-- Used by 'directory heading' pages.
local opts = ...
local t = {}
local prefix = tostring(opts.parentPath or wikiRequestPath)
prefix = tostring(prefix:match("^[^.]*")) .. "/"
for _, v in ipairs(wikiPathList(prefix)) do
	table.insert(t, h("li", {}, WikiLink(v)))
end
return {
	h("p", {}, prefix),
	h("ul", {}, t)
}
