-- Renderer for raw Lua templates.
local path, code, props, renderOptions = ...
local fn, err = load(code, path)
assert(fn, "Lua template " .. tostring(path) .. " load error: " .. tostring(err))
return fn(props, renderOptions)
