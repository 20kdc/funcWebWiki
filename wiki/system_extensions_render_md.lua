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

local function implLink(href, stuff)
	local isExternalLink = href:sub(1, 5) == "http:" or href:sub(1, 6) == "https:"
	if isExternalLink then
		table.insert(contents, h("a", {href = href}, (stuff or href)))
	else
		table.insert(contents, WikiLink(href, stuff))
	end
end

local inlineParser

local function boldParser(opposing, tag)
	return function (remainder, m)
		local backup = nil
		local res = parserWithContents(wikiParser(
			opposing, function (r2)
				backup = r2
				return ""
			end,
			inlineParser
		), remainder)
		if not backup then
			-- failed to find opposing tag! cancel.
			return m .. remainder
		end
		table.insert(contents, h(tag, {}, res))
		return backup
	end
end

inlineParser = wikiParser(
	"<([^>]+)>", function (remainder, m, href)
		implLink(href)
		return remainder
	end,
	"%[([^%]]+)%]%(([^%)]+)%)", function (remainder, m, stuff, href)
		local res = parserWithContents(inlineParser, stuff)
		implLink(href, stuff)
		return remainder
	end,
	"__", boldParser("__", "b"),
	"%*%*", boldParser("%*%*", "b"),
	"_", boldParser("_", "i"),
	"%*", boldParser("%*", "i"),
	"`([^`]+)`", function (remainder, m, stuff)
		table.insert(contents, h("code", {}, stuff))
		return remainder
	end,
	-- fastpath
	"[^<*_`%[]+",
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
	-- image or include
	"!%[([^%]]*)%]%(([^%)]+)%)\n", function (remainder, m, stuff, href)
		table.insert(contents, wikiTemplate(href, {alt = stuff, parentPath = path}))
		return remainder
	end,
	-- mixed-mode
	"```([^\n]*)\n", function (remainder, m, kind)
		if kind == "" then
			kind = "txt"
		end
		return wikiParserMatched(remainder, m, "\n```\n?", false, function (code)
			table.insert(contents, wikiRenderer(kind, true)(path, code, {}))
		end)
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
