-- Checked structure.
-- Useful for security to avoid silent failures.
local checkedStructMT = {
	__index = function (t, k)
		error("not allowed to read unknown field " .. tostring(k) .. " on a " .. tostring(rawget(t, "__kind")))
	end,
	__newindex = function (t, k)
		error("not allowed to write unknown field " .. tostring(k) .. " on a " .. tostring(rawget(t, "__kind")))
	end
}

return function (kind, v)
	v.__kind = kind
	return setmetatable(v, checkedStructMT)
end
