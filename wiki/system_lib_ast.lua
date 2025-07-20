--[[

Wiki AST elements are either:

* Nil
* Tables-without-metatables (linear lists of children)
* Tables-with-metatables (components which output specific HTML)
* Everything else is converted to string with tostring()

As a convenience feature, the `wastCanonChild` and `wastCanonNode` functions run embedded functions.

]]

wikiHtmlVoidElements = {
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

-- wiki tag metatable
WikiTag = {
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
			wastRender(writer, self.children, false)
			writer("</")
			writer(tagNameEsc)
			writer(">")
		end
	end,
	renderPlain = function (self, writer)
		wastRender(writer, self.children, true)
	end
}
WikiTag.__index = WikiTag

-- wiki raw HTML metatable
WikiRaw = {
	renderHtml = function (self, writer)
		writer(self.html)
	end,
	renderPlain = function (self, writer)
		-- 'best-effort'
		writer(self.html)
	end
}
WikiRaw.__index = WikiRaw
setmetatable(WikiRaw, {__call = function (_, html)
	return setmetatable({html = html}, WikiRaw)
end})

-- Cleans up embedded functions, arrays-in-arrays, etc.
-- This must be run as early as possible to keep errors contained properly; in particular it should be run at any error boundary.
function wastCanonChild(children, v)
	if v == nil then
		return
	end
	local tn = type(v)
	if tn == "table" then
		if not getmetatable(v) then
			for _, c in ipairs(v) do
				wastCanonChild(children, c)
			end
		else
			table.insert(children, v)
		end
	elseif tn == "function" then
		v(function (c)
			wastCanonChild(children, c)
		end)
	else
		table.insert(children, tostring(v))
	end
end

-- AST
function h(type, props, ...)
	local children = {}
	for _, v in ipairs({...}) do
		wastCanonChild(children, v)
	end
	return setmetatable({tagName = type, props = props, children = children}, WikiTag)
end

-- Renders an AST node into HTML or plaintext.
function wastRender(writer, n, plainText)
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
				wastRender(writer, v, plainText)
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
function wastRenderToString(...)
	local tmp = ""
	wastRender(function (v)
		tmp = tmp .. v
	end, ...)
	return tmp
end
-- Visits elements and text segments in an AST. (Anything that would be text is normalized to be string.)
function wastVisit(visitor, n)
	if n == nil then
		return
	end
	local tn = type(n)
	if tn == "table" then
		if getmetatable(n) then
			visitor(n)
			wastVisit(visitor, n.children)
		else
			for _, v in ipairs(n) do
				wastVisit(visitor, v)
			end
		end
	else
		visitor(tostring(n))
	end
end
