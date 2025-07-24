--[[

"Extension" to <system/lib/wikiParser> for simple opposing-token cases.

If it doesn't find it, will fail to consume (by prepending 'm' back to 'remainder').

Otherwise, handler is passed the contents inside; at this point the result is already set.

--]]
return function (remainder, m, opposed, plain, handler)
	local rs, re = remainder:find(opposed, 1, plain)
	if not rs then
        return m .. remainder
	end
	handler(remainder:sub(1, rs - 1))
	return remainder:sub(re + 1)
end
