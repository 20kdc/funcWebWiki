local path, code, opts = ...
local total = {}

local mdRenderer = wikiRenderer("md")

local function doPureLua(code)
	table.insert(total, h("pre", {}, code))
end

local function doPureMD(code)
	table.insert(total, mdRenderer(path, code, opts))
end

code = code:gsub("\r", "")

while #code > 0 do
	local nextMDBlock = code:find("\n--[[\n", 1, true)
	if code:sub(1, 5) == "--[[\n" then
		nextMDBlock = 0
	end
	if not nextMDBlock then
		doPureLua(code)
		code = ""
	else
		doPureLua(code:sub(1, nextMDBlock + 4))
		code = code:sub(nextMDBlock + 6)
		local endOfMDBlock = code:find("\n--]]\n", 1, true)
		if endOfMDBlock then
			doPureMD(code:sub(1, endOfMDBlock - 1))
			code = code:sub(endOfMDBlock + 1)
		else
			doPureMD(code)
			code = ""
		end
	end
end
return total
