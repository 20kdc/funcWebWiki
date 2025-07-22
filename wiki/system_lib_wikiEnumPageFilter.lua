-- Defines a filter for 'enumerating pages' such as <special/missingPages> and <system/action/backlinks>.
-- This prevents lagspikes as they tend to recurse into each other.
return function (path, allowSpecial)
	if path:sub(1, 13) == "system/cache/" then
		return false
	end
	if path:sub(1, 7) == "system/" then
		if GetParam("nosystem") == "1" then
			return false
		end
	end
	if (not allowSpecial) and path:sub(1, 8) == "special/" then
		return false
	end
	return true
end
