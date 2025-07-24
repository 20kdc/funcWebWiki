local path, code, props, renderOptions = ...

code = code:gsub("\r", "")

local contents = {}

local function parserWithContents(fn, ...)
	local parent, res = contents, {}
	contents = res
	assert(fn(...) == "")
	contents = parent
	return res
end

local function implLink(href, stuff, isImage)
	if isImage then
		table.insert(contents, WikiTemplate(href, table.assign({}, props, {alt = stuff, parentPath = path, inline = true})))
	else
		local isExternalLink = href:sub(1, 5) == "http:" or href:sub(1, 6) == "https:"
		if isExternalLink then
			table.insert(contents, h("a", {href = href}, (stuff or href)))
		else
			table.insert(contents, WikiLink(href, stuff))
		end
	end
end

-- Escapes (and fastpaths).
-- The only way to go deeper is to simply skip to the end character.
local inlineEscapeParser = wikiParser(
	-- 2.4, 6.7: escapes and hard line breaks: \*this\*
	-- compliance: IF A TREE FALLS IN A FOREST: no invisible syntax (would've utterly broken the fastpath)
	"\\(.)", function (remainder, m, v)
		if v == "\n" then
			table.insert(contents, h("br"))
		else
			table.insert(contents, v)
		end
		return remainder
	end,
	-- 6.9: **fastpath - any character that won't trigger another rule should be consumed here**
	-- **by extension: inline characters which do trigger rules must be added here**
	"[^<*_`%[\\!]+", function (remainder, m)
		table.insert(contents, m)
		return remainder
	end,
	-- 6.9: fallback
	function (remainder)
		table.insert(contents, remainder:sub(1, 1))
		return remainder:sub(2)
	end
)

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

-- Inline elements are given here along with examples for testing.
inlineParser = wikiParser(
	-- SmartyPants en-dash. Decided against it, but it's a good example of how the parser can be added to.
	-- Beware: you must re-add %- to the fastpath exclusion if you want to run this.
	-- `"%-%- ", function (remainder, m) table.insert(contents, "– ") return remainder end,`

	-- 6.6: raw HTML - Lua desk calculator: <?lua 1 + 1?>
	-- compliance: IT'LL DO
	-- This allows inline Lua, and by extension literally anything you want. It's _a bit_ scuffed, but preferrable to anything more 'custom'.
	-- In my personal opinion, though, I find more beauty in the `t.lua` code-blocks.
	"<%?lua ", function (remainder, m)
		return wikiParserMatched(remainder, m, "?>", true, function (code)
			local v1, v2 = load("local props, renderOptions = ... return " .. code)
			if not v1 then
				table.insert(contents, h("code", {}, tostring(v2)))
			else
				v1, v2 = wikiPCall(v1, props, renderOptions)
				if not v1 then
					table.insert(contents, h("code", {}, tostring(v2)))
				else
					table.insert(contents, v2)
				end
			end
		end)
	end,
	-- 6.6: raw HTML - comments: <!-- this text is invisible -->
	-- compliance: GREAT, ACTUALLY
	"<!%-%-", function (remainder, m)
		if remainder:sub(1, 1) == ">" then
			return remainder:sub(2)
		elseif remainder:sub(1, 2) == "->" then
			return remainder:sub(3)
		end
		return wikiParserMatched(remainder, m, "-->", true, function () end)
	end,
	-- 6.5: autolinks: <https://spec.commonmark.org/0.31.2/>
	-- 6.6: raw HTML like <u >this</u >
	-- compliance: BAD BUT FOR THE RIGHT REASONS: we overload this to implement wiki links i.e. <system/extensions/render/md>
	-- for this reason, spaces are supported so long as they are not at the start of the link (which prevents it eating, say, a < b > c).
	-- to prevent unintended capture, embedded `<>` is still prevented, and `=` can't be at the start of the link (so a <= b > c is safe).
	-- raw HTML is a mess because of all this, but to make an attempt at it, raw HTML _must_ end with either '` >`' or '` />`'.
	-- keep in mind, I don't think there's a better way to force convenient internal wiki links into Markdown than mangling this _somehow_.
	-- seeing as that's a basic usability concern, we kind of have to just live with it; the biggest issues this risks are prevented by the block parser.
	"<([^<> =][^<>]*)>", function (remainder, m, href)
		if href:sub(-1) == " " then
			-- raw HTML or it's invalid
			table.insert(contents, wikiAST.Raw(m))
			return remainder
		elseif href:sub(-2) == " /" then
			-- again, raw HTML or it's invalid
			table.insert(contents, wikiAST.Raw(m))
			return remainder
		end
		-- no spaces. it's an external link
		implLink(href)
		return remainder
	end,
	-- 6.3: links and images: [this would be nice](https://spec.commonmark.org/0.31.2/)
	-- compliance: BROKEN: Precedence, all sorts of rules
	-- the CommonMark link rules are, frankly, obscenely complex and it is not worth the effort to support them
	"!?%[([^%]]*)%]%(([^%)]+)%)", function (remainder, m, stuff, href)
		local res = parserWithContents(inlineParser, stuff)
		implLink(href, stuff, m:sub(1, 1) == "!")
		return remainder
	end,
	-- 6.2: emphasis and strong emphasis parsers
	"__", boldParser("__", "u"), -- DFM
	"%*%*", boldParser("%*%*", "b"),
	"_", boldParser("_", "i"),
	"%*", boldParser("%*", "i"),
	-- 6.1: code spans: `this` and ``this``
	-- compliance: AOK: any issues would be precedence bugs in other elements
	"`+", function (remainder, m)
		return wikiParserMatched(remainder, m, m, true, function (code)
			table.insert(contents, h("code", {}, code))
		end)
	end,
	inlineEscapeParser
)

if props.inline then
	local remainder = inlineParser(code)
	assert(remainder == "", remainder)
	return contents
else
	-- The Slightly Less-Worse Markdown Block Parser Than The One We Had Last Commit (tm) --
	-- step 1: split into lines
	local lines = {}
	while true do
		local nextLineEnd = code:find("\n")
		if not nextLineEnd then
			table.insert(lines, code)
			break
		else
			table.insert(lines, code:sub(1, nextLineEnd - 1))
			code = code:sub(nextLineEnd + 1)
		end
	end
	-- step 2: block stack
	-- blockStack entries have:
	-- * node (wikiAST node array to be appended to parent contents)
	-- * contents (optional; wikiAST node array)
	-- * handle (function (self, line) -> remainder, preserve)
	-- * blankLineAbort (boolean)
	-- * close (function (self))
	local blockStack = {}
	local function closeTopBlock()
		local topBlock = table.remove(blockStack)
		assert(topBlock, "closing non-existent block")
		topBlock:close()
	end
	local function prepareForInsert()
		local topIndex = #blockStack
		if blockStack[topIndex] then
			return blockStack[topIndex].contents
		else
			return contents
		end
	end
	local function openBlock(block)
		table.insert(prepareForInsert(), block.node)
		table.insert(blockStack, block)
	end
	local function forceCloseUntilThisBlock(block)
		while blockStack[#blockStack] ~= block do
			closeTopBlock()
		end
	end
	-- theoretically, this 'should' be handling tab=4. however, doing that caused a bunch of issues, so. uh. no?
	local function toIndent(text)
		return text:gsub("[^\t ]", " ")
	end
	local function isIndent(text, indent)
		if text:sub(1, #indent) == indent then
			return true, text:sub(#indent + 1)
		else
			return false
		end
	end
	for _, line in ipairs(lines) do
		if line:match("^[\t ]*") == line then
			for _, v in ipairs(blockStack) do
				if v.blankLineAbort then
					forceCloseUntilThisBlock(v)
					closeTopBlock()
					break
				end
			end
		else
			for _, v in ipairs(blockStack) do
				local lineMod, preserve = v:handle(line)
				line = lineMod
				if not preserve then
					forceCloseUntilThisBlock(v)
					closeTopBlock()
					break
				end
			end

			-- Log(kLogInfo, "'" .. line .. "'")
			local function listParser(remainder, m, preIndent, num)
				local itemPattern = "^([0-9]+%.[ \t]*)"
				if num == "*" then
					num = nil
					itemPattern = "^(%*[ \t]*)";
				else
					num = tostring(tonumber(num) or 1)
				end
				preIndent = toIndent(preIndent)
				local itemIndent = toIndent(m)
				local itemContents = {}
				local listItems = {itemContents}
				openBlock({
					node = {},
					contents = itemContents,
					handle = function (self, line)
						local ok, res = isIndent(line, itemIndent)
						if not ok then
							-- alright, but it could still be a new item decl
							ok, res = isIndent(line, preIndent)
							if ok then
								local m2 = res:match(itemPattern)
								if m2 then
									forceCloseUntilThisBlock(self)
									itemIndent = toIndent(preIndent .. m2)
									itemContents = {}
									table.insert(listItems, itemContents)
									self.contents = itemContents
									return res:sub(#m2 + 1), true
								end
							end
							-- it is not that, but it might be blank and therefore not really an issue
							return line, false
						else
							return res, true
						end
					end,
					blankLineAbort = false,
					close = function (self)
						local function itemConv(res)
							for _, v in ipairs(listItems) do
								res(h("li", {}, v))
							end
						end
						if num then
							table.insert(self.node, h("ol", {start = num}, itemConv))
						else
							table.insert(self.node, h("ul", {}, itemConv))
						end
					end
				})
				return remainder
			end
			local function thematicBreakParser(remainder, m)
				if remainder ~= "" then return m .. remainder end
				table.insert(prepareForInsert(), h("hr"))
				return ""
			end
			assert(wikiParser(
				-- heading
				"(#+)%s*(.*)", function (remainder, m, depth, text)
					if remainder ~= "" then return m .. remainder end
					-- Log(kLogInfo, " heading")
					local res = parserWithContents(inlineParser, text)
					table.insert(prepareForInsert(), h("h" .. tostring(#depth), {}, res))
					return ""
				end,
				-- image or include
				-- compliance: BAD, BUT FOR THE RIGHT REASONS: there is no provision in CommonMark for a 'block' image.
				-- this seems weird, as it is obviously useful and I've seen some parsers in practice support it.
				-- misusing it as an include mechanism is admittedly my doing.
				"!%[([^%]]*)%]%(([^%)]+)%)", function (remainder, m, stuff, href)
					if remainder ~= "" then return m .. remainder end
					table.insert(prepareForInsert(), WikiTemplate(href, table.assign({}, props, {alt = stuff, parentPath = path})))
					return ""
				end,
				-- thematic break. compliance: perfect, hopefully
				" ? ? ?%*[ \t]*%*[ \t]*%*+[%* \t]*", thematicBreakParser,
				" ? ? ?%-[ \t]*%-[ \t]*%-+[%- \t]*", thematicBreakParser,
				" ? ? ?%_[ \t]*%_[ \t]*%_+[%_ \t]*", thematicBreakParser,
				-- mixed-mode
				"```([^`\n]*)", function (remainder, m, kind)
					if remainder ~= "" then return m .. remainder end
					if kind == "" then
						kind = "txt"
					end
					openBlock({
						node = {},
						code = nil,
						handle = function (self, line)
							if line:sub(1, 3) == "```" then
								return line:sub(4), false
							else
								if self.code then
									self.code = self.code .. "\n" .. line
								else
									self.code = line
								end
								return "", true
							end
						end,
						blankLineAbort = false,
						close = function (self)
							-- Log(kLogInfo, self.code)
							table.insert(self.node, wikiRenderer(kind, true)(path, self.code or "", props, renderOptions))
						end
					})
					return ""
				end,
				-- numbered list
				"([ \t]*)([0-9]+)%.[ \t]*", listParser,
				-- bulleted list
				"([ \t]*)(%*)[ \t]*", listParser,
				-- blank
				"[ \t]*", function (remainder, m)
					if remainder ~= "" then return m .. remainder end
					return ""
				end,
				-- paragraph
				function (remainder)
					openBlock({
						node = {},
						text = remainder,
						handle = function (self, line)
							self.text = self.text .. "\n" .. line
							return "", true
						end,
						-- Blank lines always abort paragraphs
						blankLineAbort = true,
						close = function (self)
							table.insert(self.node, h("p", {}, parserWithContents(inlineParser, self.text)))
						end
					})
					return ""
				end
			)(line) == "")
		end
	end
	while #blockStack > 0 do
		closeTopBlock()
	end
	return contents
end
