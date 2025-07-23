local path, code, props, renderOptions = ...

code = code:gsub("\r", "")

local mdRenderer = wikiRenderer("md")

local contents = {}

--[=[ these locals are knowingly unused. ]=]
local longStringTest = [=[This is a long string.]=]

local remainder = wikiParser(
	-- comments
	"%-%-%[(=*)%[", function (remainder, m, eq)
		-- Needs to generate three segments: --[[, body, ]].
		local terminator = "]" .. eq .. "]"
		table.insert(contents, h("span", {class="code-comment"}, m))
		local sot, eot = remainder:find(terminator, 1, true)
		-- a trick to make --]] look sane
		if sot > 2 and remainder:sub(sot - 2, sot - 1) == "--" then
			sot = sot - 2
		end
		local code = remainder:sub(1, (sot or (#remainder + 1)) - 1)
		table.insert(contents, h("span", {class="code-block-comment"}, mdRenderer(path, code, {}, renderOptions)))
		if eot then
			table.insert(contents, h("span", {class="code-comment"}, remainder:sub(sot, eot)))
		end
		return remainder:sub((eot or #remainder) + 1)
	end,
	"%-%-([^\n]+)\n", function (remainder, m, content)
		table.insert(contents, h("span", {class="code-comment"}, {
			"--",
			mdRenderer(path, content, {inline = true}, renderOptions),
			"\n"
		}))
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
		local stringSpan = h("span", {class="code-string"}, total)
		local stringContent = total:sub(2, #total - 1)
		if stringContent ~= "" and (not stringContent:find("_", 1, true)) then
			local page = wikiResolvePage(stringContent)
			if page ~= path and wikiReadStamp(page) then
				stringSpan = WikiLink(page, stringSpan)
			end
		end
		table.insert(contents, stringSpan)
		return remainder
	end,
	-- long strings. it would be _really funny_ to use these like MediaWiki links, and this may be done in future if false-positives become an issue.
	-- in that event, however, it will not apply to [=[these]=], so the language still works.
	"%[(=*)%[", function (remainder, m, eq)
		local terminator = "]" .. eq .. "]"
		local sot, eot = remainder:find(terminator, 1, true)
		eot = eot or #remainder
		local code = m .. remainder:sub(1, eot)
		table.insert(contents, h("span", {class="code-string"}, code))
		return remainder:sub(eot + 1)
	end,
	-- id
	"[a-zA-Z_][a-zA-Z_0-9]*", function (remainder, m)
		local page = "system/lib/" .. m .. ".lua"
		local resolved = false
		if page ~= path then
			if wikiRead(page) then
				table.insert(contents, WikiLink(page, m))
				resolved = true
			elseif rawget(_G, m) then
				local sourceAsset = "help.txt"
				if m:sub(1, 4) == "wiki" then
					sourceAsset = "kernel.lua"
				end
				-- best-effort
				table.insert(contents, h("a", {href = wikiAbsoluteBase .. "_assets/" .. sourceAsset .. "#:~:text=" .. m}, m))
				resolved = true
			end
		end
		if not resolved then
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
