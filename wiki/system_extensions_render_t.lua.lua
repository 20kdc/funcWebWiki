-- Renderer for raw Lua templates.
local path, code, opts = ...
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
