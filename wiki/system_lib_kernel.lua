--[[

The kernel you seek is, in fact, not actually here.

Upon each request, the kernel provides a new environment, which consists of:

* A large quantity of Redbean and Lua functions.
* `Slurp`, `Barf`, `wikiDelete` (wrapped to work with the wiki's FS only)
* `wikiPathParse`, `wikiPathUnparse`, `wikiPathTable`, `wikiPathList`
* `wikiAbsoluteBase`

The kernel looks for the following wiki files:

* `system/lib/*.lua` (whenever a global is missing)
* This file (it seemed the appropriate place for the entrypoint)

--]]

-- as a half-hearted effort towards security; case-fold the action for the auth check.
-- this risks non-obvious behaviour but means case-folding OSes won't instantly brick even the most basic of read-only locks.
if wikiAuthCheckThenRenderFail(wikiRequestAction:lower(), wikiRequestPath) then
	return
end

local where = "system/action/" .. wikiRequestAction .. ".lua"
local code, err = Slurp(where)
if not code then
	if action ~= wikiDefaultAction then
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
