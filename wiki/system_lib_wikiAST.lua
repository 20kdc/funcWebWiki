--[[

Wiki AST elements are either:

* Nil
* Tables-without-metatables (linear lists of children)
* Tables-with-metatables (components which output specific HTML)
* Everything else is converted to string with tostring()

As a convenience feature, the `canonChild` function runs embedded functions.

--]]

local wikiHtmlVoidElements = {
	area = true,
	base = true,
	br = true,
	col = true,
	embed = true,
	hr = true,
	img = true,
	input = true,
	link = true,
	meta = true,
	param = true,
	source = true,
	track = true,
	wbr = true
}

local wikiAST = {}

-- Cleans up embedded functions, arrays-in-arrays, etc.
-- This must be run as early as possible to keep errors contained properly; in particular it should be run at any error boundary.
function wikiAST.canonChild(children, v)
	if v == nil then
		return
	end
	local tn = type(v)
	if tn == "table" then
		if not getmetatable(v) then
			for _, c in ipairs(v) do
				wikiAST.canonChild(children, c)
			end
		else
			table.insert(children, v)
		end
	elseif tn == "function" then
		v(function (c)
			wikiAST.canonChild(children, c)
		end)
	else
		table.insert(children, tostring(v))
	end
end

-- wiki tag metatable
wikiAST.Tag = {
	renderHtml = function (self, writer)
		writer("<")
		local tagNameEsc = EscapeHtml(self.tagName)
		writer(tagNameEsc)
		for k, v in pairs(self.props) do
			writer(" ")
			writer(EscapeHtml(k))
			writer("=\"")
			writer(EscapeHtml(v))
			writer("\"")
		end
		if wikiHtmlVoidElements[self.tagName] then
			writer(" />")
		else
			writer(" >")
			wikiAST.render(writer, self.children, false)
			writer("</")
			writer(tagNameEsc)
			writer(">")
		end
	end,
	renderPlain = function (self, writer)
		wikiAST.render(writer, self.children, true)
	end
}
wikiAST.Tag.__index = wikiAST.Tag
setmetatable(wikiAST.Tag, {__call = function (self, type, props, ...)
	local children = {}
	for _, v in ipairs({...}) do
		wikiAST.canonChild(children, v)
	end
	return setmetatable({tagName = type, props = props, children = children}, self)
end})

-- wiki raw HTML metatable
wikiAST.Raw = {
	renderHtml = function (self, writer)
		writer(self.html)
	end,
	renderPlain = function (self, writer)
		-- 'best-effort'
		writer(self.html)
	end
}
wikiAST.Raw.__index = wikiAST.Raw
setmetatable(wikiAST.Raw, {__call = function (self, html)
	return setmetatable({html = html}, self)
end})

-- Renders an AST node into HTML or plaintext.
function wikiAST.render(writer, n, plainText)
	if n == nil then
		return
	end
	local tn = type(n)
	if tn == "table" then
		if getmetatable(n) then
			local name = "renderHtml"
			if plainText then
				name = "renderPlain"
			end
			local fn = n[name]
			if not fn then
				error("bad node: " .. tostring(n))
			end
			fn(n, writer)
		else
			for _, v in ipairs(n) do
				wikiAST.render(writer, v, plainText)
			end
		end
	else
		if plainText then
			writer(tostring(n))
		else
			writer(EscapeHtml(tostring(n)))
		end
	end
end
function wikiAST.renderToString(...)
	local tmp = ""
	wikiAST.render(function (v)
		tmp = tmp .. v
	end, ...)
	return tmp
end
-- Visits elements and text segments in an AST. (Anything that would be text is normalized to be string.)
function wikiAST.visit(visitor, n)
	if n == nil then
		return
	end
	local tn = type(n)
	if tn == "table" then
		if getmetatable(n) then
			visitor(n)
			wikiAST.visit(visitor, n.children)
		else
			for _, v in ipairs(n) do
				wikiAST.visit(visitor, v)
			end
		end
	else
		visitor(tostring(n))
	end
end

return wikiAST
