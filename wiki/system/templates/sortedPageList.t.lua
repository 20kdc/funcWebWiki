local props = ...
local pageList = props.pageList or {}

-- precompute stylized plaintext for all possible entries
local stylizedPlain = {}
for _, v in ipairs(pageList) do
	stylizedPlain[v] = wikiAST.renderToString(wikiTitleStylize(v), {renderType = "renderPlain"})
end
table.sort(pageList, function (a, b) return stylizedPlain[a] < stylizedPlain[b] end)

local function handleLevel(pageList, prefix, tree)
	if (not tree) or (type(tree) == "number" and (tree <= 0)) then
		return h("ul", {class = "page-list-flat"}, {
			function (res)
				for _, v in ipairs(pageList) do
					res(h("li", {}, WikiLink(v)))
				end
			end
		})
	else
		local nextTree = tree
		if type(tree) == "number" then
			nextTree = nextTree - 1
		end
		local thisLevel = {}
		local thisLevelList = {}
		for _, v in ipairs(pageList) do
			local vChk = wikiExtStripIfClear(v)
			if v:sub(1, 8) == "special/" then
				-- bypass to make these behave
				table.insert(thisLevelList, {
					link = v,
					linkReal = true,
					text = v,
					children = {}
				})
			elseif vChk:sub(1, #prefix) == prefix then
				local rest = vChk:sub(#prefix + 1)
				local brk = rest:find("/", 1, true)
				local component = rest
				if brk then
					component = component:sub(1, brk - 1)
				end
				local isChild = brk
				-- prefix: "prefix/"
				-- v: "prefix/root"
				-- component: "root"
				-- extLess: "root"
				-- stem: root
				-- strip leading/trailing spaces from stem
				local stem = component
				while stem:sub(1, 1) == " " do
					stem = stem:sub(2)
				end
				while stem:sub(-1) == " " do
					stem = stem:sub(1, -2)
				end
				-- stem data...
				local setPrefix = prefix .. component .. "/"
				local stemData = thisLevel[stem] or {
					link = prefix .. component,
					text = component,
					prefix = setPrefix,
					children = {}
				}
				if not thisLevel[stem] then
					table.insert(thisLevelList, stemData)
				end
				thisLevel[stem] = stemData
				if isChild then
					table.insert(stemData.children, v)
				else
					stemData.link = v
					stemData.linkReal = true
				end
			end
		end
		return h("ul", {class = "page-list-tree"}, {
			function (res)
				for pass = 1, 2 do
					for _, v in ipairs(thisLevelList) do
						-- prevent including bases in the title
						-- it risks display oddities w/ custom titles
						-- but what can 'ya do?
						local sumComp = wikiTitleStylize(v.link, v.text)
						if v.linkReal then
							sumComp = WikiLink(v.link, sumComp)
						end
						local hasChildren = #v.children > 0
						-- bad sorting...
						if hasChildren and pass == 2 then
							res(h("li", {},
								h("details", {},
									h("summary", {}, sumComp),
									-- "[DBG", stem, "]",
									handleLevel(v.children, v.prefix, nextTree)
								)
							))
						elseif (not hasChildren) and pass == 1 then
							res(h("li", {}, sumComp))
						end
						res("\n")
					end
				end
			end
		})
	end
end

return handleLevel(pageList, "", props.tree)
