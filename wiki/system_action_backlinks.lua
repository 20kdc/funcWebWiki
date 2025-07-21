-- Finds backlinks to the page.

local requestPath, requestExt = ...

local lst = wikiPathList()

local res = {}

for _, v in ipairs(lst) do
	if wikiEnumPageFilter(v) then
		if wikiPageLinks(v)[requestPath] then
			table.insert(res, v)
		end
	end
end

wikiAST.render(Write, wikiTemplate("system/index/frame", {
	title = {"Links to: ", wikiTitleStylize(requestPath)},
	parentPath = requestPath,
	path = "system/templates/sortedPageList",
	opts = {
		pageList = res
	}
}))
