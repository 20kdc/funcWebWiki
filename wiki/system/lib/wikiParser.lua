--[[

Simple parsing library. wikiParser is based on the 'visitor' model similar to lex/yacc.

To create a parser, wikiParser is called. This creates a parsing function, passed `(remainder[, single])` (what is left to parse, and a special flag used in recursion).

Each pair of args to wikiParser makes up a pair (pattern, handler).

Normally, these patterns are evaluated one at a time until one matches; then the loop restarts. If `single` is passed, the loop only goes through one iteration.

The pattern is always implicitly prefixed with "^(" and suffixed with ")"; this is to anchor it at the start of the string and ensure the first capture is always the entire pattern.

The handler is a function that is passed the remainder (the match has been skipped already, so 'return remainder' works), followed by the results of string.match. The handler returns the new remainder.

If the new remainder the handler returns is equal to the original (before the match was skipped), it is as if it hadn't matched at all; the loop does not restart.

If there is a 'loose' arg at the end, this represents a fallback handler, passed the remainder to parse, along with true (single-iteration).

A wikiParser is itself a valid fallback handler; the `single` flag ensures that only the outer-most loop is used in this case.

The parser will return when the remainder is empty or when it appears deadlocked (the input remainder is the same as the output).

If a parser is only interested in occasional 'markup' characters and passes through the rest unchanged, it may be best to have a 'broad' pattern encompassing all non-special characters to handle large swaths and a byte-by-byte fallback handler to handle tricky cases with care.

--]]

local function wikiParser(...)
	local p = {...}
	local pl = #p
	return function (remainder, single)
		while remainder ~= "" do
			local inputRemainder = remainder
			local i = 1
			while i < pl do
				local pattern, handler = p[i],  p[i + 1]
				local match = {string.match(remainder, "^(" .. pattern .. ")", 1)}
				if match[1] then
					remainder = handler(remainder:sub(#match[1] + 1), table.unpack(match))
					if inputRemainder ~= remainder then
						-- made forward progress, restart loop
						break
					end
				end
				i = i + 2
			end
			if i == pl then
				-- a fallback exists and was reached
				remainder = p[i](remainder, true)
			end
			if single or inputRemainder == remainder then
				break
			end
		end
		return remainder
	end
end

return wikiParser
