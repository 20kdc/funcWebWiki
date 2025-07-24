-- In order to prevent issues on case-insensitive filesystems, we prepare a full, known-good table of parsed actions here.
-- This table is 'dual-mode'; it can be iterated with `ipairs` or indexed.
-- What you absolutely _shouldn't_ do with it is call `pairs`.

local actionTable = {}

for _, v in ipairs(wikiPathList("system/action/")) do
	-- (prefix...)/action[.z][.w].lua
	local action, typeIndicator = v:match("/([^./]+)([^/]+)$")
	if action then
		local nameResolved = wikiResolvePage("system/actionName/" .. action)
		local nameTemplate = function () return action end
		if wikiReadStamp(nameResolved) then
			nameTemplate = nameResolved
		end
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

return actionTable
