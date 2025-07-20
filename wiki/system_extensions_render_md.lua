local path, code, opts = ...

local contents = {}

local remainder = wikiParser(
	"<([^>]+)>", function (remainder, m, href)
		local isExternalLink = href:sub(1, 5) == "http:" or href:sub(1, 6) == "https:"
		if isExternalLink then
			table.insert(contents, h("a", {href = href}, href))
		else
			table.insert(contents, WikiLink(href))
		end
		return remainder
	end,
	-- fastpath
	"[^<]+",
	function (remainder, m)
		table.insert(contents, m)
		return remainder
	end,
	-- fallback
	function (remainder)
		table.insert(contents, remainder:sub(1, 1))
		return remainder:sub(2)
	end
)(code)

assert(remainder == "", remainder)

if opts.inline then
	return contents
else
	return h("pre", {}, contents)
end
