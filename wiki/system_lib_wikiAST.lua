--[[

Wiki AST elements are either:

* Nil
* Tables-without-metatables (linear lists of children)
* Tables-with-metatables (components which output specific HTML)
* Everything else is converted to string with tostring()

As a convenience feature, the `canonChild` function runs embedded functions.

Render options are:

* `renderType`: How the element is being rendered.
* `disableErrorIsolation`: Disables error isolation in various components.
* `getParam`: If not nil, then this gets a parameter. Use `renderOptions.getParam and renderOptions.getParam("param")`.

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
	assert(methods.visit, "wikiAST nodes must have at least visit = function (self, writer, renderOptions), which forwards child nodes to wikiAST.render (or does nothing)")

	-- nodes auto-implement renderers as "skip/descend"
	methods.renderHtml = methods.renderHtml or methods.visit
	methods.renderPlain = methods.renderPlain or methods.visit

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
	visit = function (self, writer, renderOptions)
		wikiAST.render(writer, self.children, renderOptions)
	end
}, function (self, tagName, props, ...)
	props = props or {}
	assert(type(props) == "table", "props must be k/v table")
	local children = {}
	for _, v in ipairs({...}) do
		wikiAST.canonChild(children, v)
	end
	return setmetatable({tagName = tagName, props = props, children = children}, self)
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
	end,
	visit = function (self, writer, renderOptions)
	end
}, function (self, html)
	return setmetatable({html = html}, self)
end)

--[[
Renders an AST node into HTML or plaintext.
`renderOptions` can contain `renderType`, which can be:
* `renderPlain` to render plain text.
* `visit` is similar to `renderPlain`, but calls `writer` with each component. (Notably, this cannot be used for plaintext search. Use `renderPlain` for that.)
--]]
function wikiAST.render(writer, n, renderOptions)
	if n == nil then
		return
	end
	renderOptions = renderOptions or {}
	local renderType = renderOptions.renderType or "renderHtml"
	local tn = type(n)
	if tn == "table" then
		if getmetatable(n) then
			if renderType == "visit" then
				writer(n)
			end
			local fn = n[renderType]
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
		if renderType == "renderHtml" then
			writer(EscapeHtml(tostring(n)))
		elseif renderType == "renderPlain" then
			writer(tostring(n))
		end
	end
end

-- Renders to the Redbean Write function.
-- Assumes that renderOptions (if provided) has been immediately generated and modifies it accordingly.
function wikiAST.serveRender(n, renderOptions)
	renderOptions = renderOptions or {}
	renderOptions.getParam = GetParam
	if renderOptions.renderType == "renderPlain" then
		SetHeader("Content-Type", "text/plain")
	else
		SetHeader("Content-Type", "text/html")
	end
	wikiAST.render(Write, n, renderOptions)
end

-- Convenience function to create a string.
function wikiAST.renderToString(...)
	local tmp = ""
	wikiAST.render(function (v)
		tmp = tmp .. v
	end, ...)
	return tmp
end

return wikiAST
