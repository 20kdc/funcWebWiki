local path, code, opts = ...

code = code:gsub("\r", "")

local mdRenderer = wikiRenderer("md")

local contents = {}

local remainder = wikiParser(
	-- comments
	"%-%-%[(=*)%[", function (remainder, m, eq)
		local terminator = "]" .. eq .. "]"
		local _, eot = remainder:find(terminator, 1, true)
		if not eot then
			eot = #remainder
		end
		local code = m .. remainder:sub(1, eot)
		table.insert(contents, h("span", {class="code-comment"}, mdRenderer(path, code, {})))
		return remainder:sub(eot + 1)
	end,
	"%-%-[^\n]+\n", function (remainder, m)
		table.insert(contents, h("span", {class="code-comment"}, mdRenderer(path, m, {inline = true})))
		return remainder
	end,
	-- strings
	"[\"\']", function (remainder, m)
		local opposing = m
		local total = m
		local function verbatim(remainder, m)
			total = total .. m
			return remainder
		end
		remainder = wikiParser(
			"\\'", verbatim,
			"\\\"", verbatim,
			"\\\\", verbatim,
			"\\", verbatim,
			"[^\\'\"]+", verbatim,
			function (remainder)
				if remainder:sub(1, 1) == opposing then
					return remainder
				end
				total = total .. remainder:sub(1, 1)
				return remainder:sub(2)
			end
		)(remainder)
		total = total .. remainder:sub(1, 1)
		remainder = remainder:sub(2)
		table.insert(contents, h("span", {class="code-string"}, total))
		return remainder
	end,
	-- id
	"[a-zA-Z_][a-zA-Z_0-9]*", function (remainder, m)
		local page = "system/lib/" .. m .. ".lua"
		if page ~= path and Slurp(page) then
			table.insert(contents, WikiLink(page, m))
		else
			table.insert(contents, m)
		end
		return remainder
	end,
	-- fallback
	function (remainder)
		table.insert(contents, remainder:sub(1, 1))
		return remainder:sub(2)
	end
)(code)

assert(remainder == "", remainder)

return h("pre", {}, contents)
