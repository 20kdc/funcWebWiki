-- A renderer receives (path, code, opts) and returns a <system/lib/wikiAST> node.

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

local function wikiRenderer(templateExt)
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
					h("pre", {}, tostring(err)),
					lastResortRenderer(path, code, opts)
				}
			end
		end
		rendererCache[templateExt] = renderer
	end
	return renderer
end

return wikiRenderer
