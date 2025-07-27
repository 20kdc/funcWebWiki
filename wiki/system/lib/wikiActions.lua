-- In order to prevent issues on case-insensitive filesystems, we prepare a full, known-good table of parsed actions here.
-- This table is 'dual-mode'; it can be iterated with `ipairs` or indexed.
-- What you absolutely _shouldn't_ do with it is call `pairs`.

local actionTable = {}

for _, v in ipairs(wikiPathList("system/action/")) do
	-- (prefix...)/action[.z][.w].lua
	local action, typeIndicator = v:match("/([^./]+)([^/]+)$")
	if action then
		local nameTemplate = function () return action end
		local struct = wikiCheckedStruct("WikiParsedAction", {
			path = v,
			action = action,
			nameTemplate = nameTemplate,
			-- ".z." is consistently used to indicate 'hidden' now.
			-- It might be an idea to unify the flag-parsing code, but that means adding even more pages.
			hidden = not not typeIndicator:match(".z.", 1, true),
			mutator = not not typeIndicator:match(".w.", 1, true)
		})
		actionTable[action] = struct
		table.insert(actionTable, struct)
	end
end
for _, v in ipairs(wikiPathList("system/actionName/")) do
	local forAction = v:match("/([^./]+)[^/]+$")
	if forAction then
		-- Log(kLogInfo, "! " .. v .. " = " .. forAction)
		local action = actionTable[forAction]
		if action then
			action.nameTemplate = v
		end
	end
end

return actionTable
