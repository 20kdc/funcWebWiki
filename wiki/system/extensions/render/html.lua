local path, code, props, renderOptions = ...
local finale = {}
-- very fast copy
local at = 1
while at <= #code do
	local nxt = code:find("<?lua ", at, true)
	if nxt then
		table.insert(finale, wikiAST.Raw(code:sub(at, nxt - 1)))
		at = nxt + 6
		nxt = code:find("?>", at, true)
		local seg
		if nxt then
			seg = code:sub(at, nxt - 1)
			at = nxt + 2
		else
			seg = code:sub(at)
			at = #code + 1
		end
		wikiEvalLuaInsert(finale, seg, path, props, renderOptions)
	else
		table.insert(finale, wikiAST.Raw(code:sub(at)))
		break
	end
end
return finale
