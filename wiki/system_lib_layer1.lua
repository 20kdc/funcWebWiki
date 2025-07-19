--[[

The <system/lib/kernel> secures things and provides the basic framework.

This layer provides the actual architecture of the templating system.

This layer is made up of the following:

* <system/lib/layer1>: This file.
* <system/action/default>: Passes to <system/templates/frame?action=raw>.
* <system/action/raw>: Used for images, etc.

This layer looks for the following:

* Renderers, i.e. <system/extensions/render/lua.lua>
* Mime-types, i.e. <system/extensions/mime/lua.txt>
* <system/templates/frame>: Site's general theme, basically. If this is missing the site kinda can't work properly.
* <system/templates/missingTemplate>: Custom missing template message (there's a built-in fallback, though).

--]]

function wikiHtmlSimpleLink(href, text)
	Write("<a href=\"" .. EscapeHtml(tostring(href)) .. "\">" .. EscapeHtml(tostring(text)) .. "</a>")
end

function wikiExtToMime(ext)
	while true do
		local res = wikiReadConfig("system/extensions/mime/" .. ext .. ".txt", nil)
		if res then
			return res
		end
		local idx = ext:find(".", 1, true)
		if not idx then
			return nil
		end
		ext = ext:sub(idx + 1)
	end
end

local rendererCache = {
	-- Renderer for raw HTML
	["html"] = function (path, code, opts)
		Write(code)
	end,
	-- Renderer for raw Lua templates
	["t.lua"] = function (path, code, opts)
		local fn, err = load(code, path)
		if not fn then
			Write("<pre>Lua template " .. EscapeHtml(tostring(path)) .. " load error: " .. EscapeHtml(tostring(err)) .. "</pre>")
		end
		fn, err = pcall(fn, opts)
		if not fn then
			Write("<pre>Lua template " .. EscapeHtml(tostring(path)) .. " run error: " .. EscapeHtml(tostring(err)) .. "</pre>")
		end
	end
}

-- A renderer receives (path, code, opts) and calls Write.
function wikiLoadRenderer(templateExt)
	local function lastResortRenderer(path, code, opts)
		if wikiExtToMime(templateExt):sub(1, 5) == "text/" then
			Write("<pre>" .. EscapeHtml(code) .. "</pre>")
		else
			Write("<img src=\"" .. EscapeHtml(path) .. "?action=raw\"/>")
		end
	end

	local renderer = rendererCache[templateExt]
	local err
	if not renderer then
		local rendererPath = "system/extensions/render/" .. templateExt .. ".lua"
		local rendererCode = Slurp(rendererPath)
		if not rendererCode then
			renderer = lastResortRenderer
		else
			renderer, err = load(rendererCode, rendererPath)
			renderer = renderer or function (path, code, opts)
				Write("<p>Renderer " .. EscapeHtml(rendererPath) .. " could not be loaded.</p>")
				Write("<pre>" .. EscapeHtml(tostring(rendererErr)) .. "</pre>")
				lastResortRenderer(path, code, opts)
			end
		end
		rendererCache[templateExt] = renderer
	end
	return renderer
end

local templateCache = {}

-- All pages are 'templates'.
-- Thus wikiLoadTemplate loads a page for rendering.
-- The resulting functions are passed the options table.
function wikiLoadTemplate(template)
	local templatePath, templateExt = wikiResolvePage(template)
	if templateCache[templatePath] then
		return templateCache[templatePath]
	end
	local code, codeErr = Slurp(templatePath)
	if not code then
		local res
		if template == "system/templates/missingTemplate" then
			-- system/templates/missingTemplate has a fallback to prevent recursion
			res = function (opts)
				Write("(")
				wikiHtmlSimpleLink(tostring(opts.path) .. "?action=edit", tostring(opts.path))
				Write(" missing)")
			end
		else
			-- so the order proceeds:
			-- system/{template}
			-- system/templates/missingTemplate
			-- (built-in)
			local missingTemplate = wikiLoadTemplate("system/templates/missingTemplate")
			res = function (opts)
				missingTemplate({
					path = templatePath,
					opts = opts
				})
			end
		end
		templateCache[templatePath] = res
		return res
	end
	local renderer = wikiLoadRenderer(templateExt)
	local res = function (opts)
		renderer(templatePath, code, opts)
	end
	templateCache[templatePath] = res
	return res
end
