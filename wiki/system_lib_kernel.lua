--[[

The kernel you seek is, in fact, not actually here; but here is how it works.

Firstly, if the request path starts with `/_assets/`, the asset is served from Redbean's asset system.

This means that, i.e. `/_assets/help.txt` gives the Redbean developer help.

Upon each request, the kernel provides a new environment, which consists of:

* A large quantity of Redbean and Lua functions.
* `table.assign`, `table.deepcopy`
* `Slurp`, `Barf`, `wikiDelete` (wrapped to work with the wiki's FS only)
* `wikiPathParse`, `wikiPathUnparse`, `wikiPathTable`, `wikiPathList`
* `wikiAbsoluteBase`
* `wikiReadOnly` (assets are being read via the Redbean asset system, wiki is fully immutable)

The kernel looks for the following wiki files:

* `system/lib/*.lua` (whenever a global is missing)
* This file (it seemed the appropriate place for the entrypoint)

--]]

-- The action parameter of the request.
local requestAction = GetParam("action") or wikiDefaultAction

local requestPath, requestExt = wikiResolvePage(GetPath())

-- as a half-hearted effort towards security; case-fold the action for the auth check.
-- this risks non-obvious behaviour but means case-folding OSes won't instantly brick even the most basic of read-only locks.
if wikiAuthCheckThenRenderFail(requestAction:lower(), requestPath) then
	return
end

local where = "system/action/" .. requestAction .. ".lua"
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
actionFn(requestPath, requestExt)
