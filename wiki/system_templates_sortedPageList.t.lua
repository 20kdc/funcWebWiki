local props = ...

local leftBar = props.pageList or {}

local stylizedPlain = {}
for _, v in ipairs(leftBar) do
	stylizedPlain[v] = wikiAST.renderToString(wikiTitleStylize(v), {renderType = "renderPlain"})
end
table.sort(leftBar, function (a, b) return stylizedPlain[a] < stylizedPlain[b] end)

return {
	h("ul", {}, {
		function (res)
			for _, v in ipairs(leftBar) do
				res(h("li", {},
					WikiLink(v)
				))
				res("\n")
			end
		end
	})
}
