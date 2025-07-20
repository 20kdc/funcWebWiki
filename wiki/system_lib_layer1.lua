--[[

The <system/lib/kernel> secures things and provides the basic framework.

This layer provides the actual architecture of the templating system.

This layer is made up of the following:

* <system/lib/layer1>: This file.
* <system/lib/ast>: The AST core.
* <system/lib/wikilink>: Related to AST core - Handles the styling of wiki page names and links.
* <system/action/default>: Passes to <system/templates/frame?action=raw>.
* <system/action/raw>: Used for images, etc.

This layer looks for the following:

* Renderers, i.e. <system/extensions/render/lua.lua>
* Mime-types, i.e. <system/extensions/mime/lua.txt>
* <system/templates/frame>: Site's general theme, basically. If this is missing the site kinda can't work properly.
* <system/templates/missingTemplate>: Custom missing template message (there's a built-in fallback, though).

--]]

require("system/lib/ast.lua")

-- Extension-to-MIME

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
		return WikiRaw(code)
	end,
	-- Renderer for raw Lua templates
	["t.lua"] = function (path, code, opts)
		local fn, err = load(code, path)
		if not fn then
			return h("pre", {},
				"Lua template ",
				tostring(path),
				" load error: ",
				tostring(err)
			)
		end
		local ok, res = xpcall(fn, function (obj)
			return debug.traceback(coroutine.running(), EncodeLua(obj))
		end, opts)
		if not ok then
			return h("pre", {},
				"Lua template ",
				tostring(path),
				"\n",
				tostring(res)
			)
		end
		return res
	end
}

-- A renderer receives (path, code, opts) and returns AST.
function wikiLoadRenderer(templateExt)
	local function lastResortRenderer(path, code, opts)
		if wikiExtToMime(templateExt):sub(1, 5) == "text/" then
			return h("pre", {}, code)
		else
			return h("img", {src=(wikiAbsoluteBase .. path .. "?action=raw")}, code)
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
				return {
					h("p", {}, "Renderer " .. rendererPath .. " could not be loaded."),
					h("pre", {}, tostring(rendererErr)),
					lastResortRenderer(path, code, opts)
				}
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
				return {
					"(",
					h("a", {href = tostring(opts.path) .. "?action=edit"},
						tostring(opts.path)
					),
					" missing)"
				}
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
		return renderer(templatePath, code, opts)
	end
	templateCache[templatePath] = res
	return res
end
