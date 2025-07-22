-- Checked structure.
-- Useful for security to avoid silent failures.
local checkedStructMT = {
	__index = function (table, key)
		error("not allowed to read unknown field " .. tostring(key) .. " on a " .. tostring(rawget(table, "__kind")))
	end,
	__newindex = function (table, key)
		error("not allowed to write unknown field " .. tostring(key) .. " on a " .. tostring(table.__kind))
	end
}

return function (kind, v)
	v.__kind = kind
	return setmetatable(v, checkedStructMT)
end
