--[[

Iterates extensions from broadest to least broad.
Test with `for v in makeEnv().wikiExtIter("d.e.f") do print(v) end` in REPL.
Should output "d.e.f", "e.f", "f".

--]]

local function myIterator(state, ext)
	local x = ext:find(".", 1, true)
	if not x then
		-- we're done
		return
	end
	ext = ext:sub(x + 1)
	return ext
end

return function (ext)
	return myIterator, 0, "." .. ext
end