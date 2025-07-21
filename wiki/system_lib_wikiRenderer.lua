-- A renderer receives (path, code, opts) and returns a <system/lib/wikiAST> node.

local rendererCache = {
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

local function wikiRenderer(templateExt, promiseThisIsText)
	local function lastResortRenderer(path, code, opts)
		if promiseThisIsText or (wikiExtToMime(templateExt) or ""):sub(1, 5) == "text/" then
			return h("pre", {}, code)
		else
			return WikiLink(path, { opts.alt }, "raw", "image")
		end
	end

	local renderer = rendererCache[templateExt]
	local err
	if not renderer then
		for ext in wikiExtIter(templateExt) do
			local rendererPath = "system/extensions/render/" .. ext .. ".lua"
			local rendererCode = Slurp(rendererPath)
			if rendererCode then
				renderer, err = load(rendererCode, rendererPath)
				renderer = renderer or function (path, code, opts)
					return {
						h("p", {}, "Renderer " .. rendererPath .. " could not be loaded."),
						h("pre", {}, tostring(err)),
						lastResortRenderer(path, code, opts)
					}
				end
				break
			end
		end
		renderer = renderer or lastResortRenderer
		rendererCache[templateExt] = renderer
	end
	return renderer
end

return wikiRenderer
