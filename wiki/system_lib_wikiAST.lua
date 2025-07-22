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

-- New AST class. Checks for validity.
function wikiAST.newClass(methods, constructor)
	assert(methods.renderHtml)
	assert(methods.renderPlain)
	methods.__index = methods
	setmetatable(methods, {__call = constructor})
	return methods
end

-- HTML tag node: wikiAST.Tag("a", {href = "..."}, "Link text.")
wikiAST.Tag = wikiAST.newClass({
	renderHtml = function (self, writer, renderOptions)
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
			wikiAST.render(writer, self.children, renderOptions)
			writer("</")
			writer(tagNameEsc)
			writer(">")
		end
	end,
	renderPlain = function (self, writer, renderOptions)
		wikiAST.render(writer, self.children, renderOptions)
	end
}, function (self, type, props, ...)
	local children = {}
	for _, v in ipairs({...}) do
		wikiAST.canonChild(children, v)
	end
	return setmetatable({tagName = type, props = (props or {}), children = children}, self)
end)

-- Raw HTML node: `wikiAST.Raw("...")`
-- A word of warning: Do not pass rendered output here.
-- That will break link tracking, which is no fun!
wikiAST.Raw = wikiAST.newClass({
	renderHtml = function (self, writer, renderOptions)
		writer(self.html)
	end,
	renderPlain = function (self, writer, renderOptions)
		-- 'best-effort'
		writer(self.html)
	end
}, function (self, html)
	return setmetatable({html = html}, self)
end)

-- Renders an AST node into HTML or plaintext.
-- `renderOptions` can contain `renderType`, which can be `renderPlain` to render plain text.
function wikiAST.render(writer, n, renderOptions)
	if n == nil then
		return
	end
	renderOptions = renderOptions or {}
	local tn = type(n)
	if tn == "table" then
		if getmetatable(n) then
			local name = renderOptions.renderType or "renderHtml"
			local fn = n[name]
			if not fn then
				error("bad node: " .. tostring(n))
			end
			fn(n, writer, renderOptions)
		else
			for _, v in ipairs(n) do
				wikiAST.render(writer, v, renderOptions)
			end
		end
	else
		if renderOptions.renderType == "renderPlain" then
			writer(tostring(n))
		else
			writer(EscapeHtml(tostring(n)))
		end
	end
end

-- Convenience function to create a string.
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
