-- Defines a filter for 'enumerating pages' such as <special/missingPages> and <system/action/backlinks>.
-- This prevents lagspikes as they tend to recurse into each other.
return function (path)
	if path:sub(1, 7) == "system/" then
		if GetParam("nosystem") == "1" then
			return false
		end
	end
	if path:sub(1, 8) == "special/" then
		return false
	end
	return true
end
