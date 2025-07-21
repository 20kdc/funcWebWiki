-- Finds backlinks to the page.

local lst = wikiPathList()

local res = {}

for _, v in ipairs(lst) do
	if wikiEnumPageFilter(v) then
		local rendered = wikiTemplate(v, wikiDefaultOpts)
		local hasLinked = false
		wikiAST.visit(function (node)
			if hasLinked then
				return
			end
			if getmetatable(node) == WikiLink then
				if wikiResolvePage(node.page) == wikiRequestPath then
					hasLinked = true
				end
			end
		end, rendered)
		if hasLinked then
			table.insert(res, v)
		end
	end
end

-- <system/templates/frame>
wikiAST.render(Write, wikiTemplate("system/templates/frame", {
	title = {"Links to: ", wikiTitleStylize(wikiRequestPath)},
	path = "system/templates/sortedPageList",
	opts = {
		pageList = res
	}
}))
