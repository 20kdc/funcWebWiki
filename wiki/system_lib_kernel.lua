--[[

The kernel you seek is, in fact, not actually here.

The kernel provides the environment for actions, which consists of:

* A large quantity of Redbean and Lua functions.
* `Slurp`, `Barf`, `wikiDelete` (wrapped to work with the wiki's FS only)
* `wikiPathParse`, `wikiPathUnparse`, `wikiPathTable`, `wikiPathList`
* `wikiAbsoluteBase`

The kernel looks for the following wiki files:

* `system/lib/*.lua` (whenever a global is missing)
* This file (it seemed the appropriate place for the entrypoint)

--]]

-- Kernel routes to system/action/{action}.lua
local where = "system/action/" .. wikiRequestAction .. ".lua"
local code, err = Slurp(where)
if not code then
	if action ~= "default" then
		ServeRedirect(303, GetPath())
		return
	else
		Write(Slurp(wikiPath))
		return
	end
end
local actionFn, actionFnErr = load(code, where, "t")
assert(actionFn, actionFnErr)
actionFn()
