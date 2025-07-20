local path, code, opts = ...

code = code:gsub("\r", "")

local contents = {}

local function parserWithContents(fn, ...)
	local parent, res = contents, {}
	contents = res
	assert(fn(...) == "")
	contents = parent
	return res
end

local inlineParser
inlineParser = wikiParser(
	"<([^>]+)>", function (remainder, m, href)
		local isExternalLink = href:sub(1, 5) == "http:" or href:sub(1, 6) == "https:"
		if isExternalLink then
			table.insert(contents, h("a", {href = href}, href))
		else
			table.insert(contents, WikiLink(href))
		end
		return remainder
	end,
	"_([^_]+)_", function (remainder, m, stuff)
		local res = parserWithContents(inlineParser, stuff)
		table.insert(contents, h("i", {}, res))
		return remainder
	end,
	"`([^`]+)`", function (remainder, m, stuff)
		local res = parserWithContents(inlineParser, stuff)
		table.insert(contents, h("code", {}, res))
		return remainder
	end,
	-- fastpath
	"[^<*_`]+",
	function (remainder, m)
		table.insert(contents, m)
		return remainder
	end,
	-- fallback
	function (remainder)
		table.insert(contents, remainder:sub(1, 1))
		return remainder:sub(2)
	end
)

local paraParser
paraParser = wikiParser(
	-- heading
	"(#+)%s*([^\n]*)\n", function (remainder, m, depth, text)
		local res = parserWithContents(inlineParser, text)
		table.insert(contents, h("h" .. tostring(#depth), {}, res))
		return remainder
	end,
	-- mixed-mode
	"```([^\n]*)\n", function (remainder, m, kind)
		local rs, re = remainder:find("\n```\n", 1, true)
		if not re then
			rs = #remainder + 1
			re = #remainder + 1
		end
		if kind == "" then
			kind = "txt"
		end
		local code = remainder:sub(1, rs - 1)
		table.insert(contents, wikiRenderer(kind, true)(path, code, {}))
		return remainder:sub(re + 1)
	end,
	-- general-case line
	"([^\n]*)\n", function (remainder, m, stuff)
		local res = parserWithContents(inlineParser, stuff)
		table.insert(contents, h("p", {}, res))
		return remainder
	end,
	-- fallback
	function (remainder)
		if remainder ~= "" then
			local res = parserWithContents(inlineParser, remainder)
			table.insert(contents, h("p", {}, res))
		end
		return ""
	end
)

if opts.inline then
	local remainder = inlineParser(code)
	assert(remainder == "", remainder)
	return contents
else
	local remainder = paraParser(code)
	assert(remainder == "", remainder)
	return contents
end
