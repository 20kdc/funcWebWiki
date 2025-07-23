--[[

This is the entrypoint called by the 'kernel' for each request.

Here is how things happen there:

First, three rules (that can be controlled from the command-line):
* The request path may be optionally stripped of a prefix, which is replaced with "/".
* If the request path starts with `/_assets/`, the asset is served from Redbean's asset system.
  This means that, i.e. `/_assets/help.txt` gives the Redbean developer help.
* `/favicon.ico` is also served from Redbean's `favicon.ico`.

If `WIKI_TWM_PASSWORD` is in the environment, the query parameter `_twm` is checked.
If it is equal to the password, the 'tactical witch mode' editor is served.

Upon each request, a new environment is created, which consists of:

* A large quantity of Redbean and Lua functions.
* `table.assign(target, sources...) -> target`, `table.deepcopy(source) -> copy`
* `wikiRead(path) -> data | nil, err`, `wikiReadStamp(path) -> length, stamp | nil, nil, err`
* `wikiWrite(path, data) -> true | nil, err`, `wikiDelete(path) -> true | nil, err`
* `wikiPathParse(path) -> parsed | nil, err`, `wikiPathUnparse(parsed) -> path`, `wikiPathTable([prefix]) -> paths`, `wikiPathList([prefix]) -> paths`
* `wikiAbsoluteBase`
* `wikiReadOnly` (assets are being read via the Redbean asset system, wiki is fully immutable)

`kernel.lua` looks for the following wiki files:

* <system/lib>: `system/lib/*.lua` (whenever a global is missing)
* <system/trigger>: `system/trigger/*.lua` (the `--trigger` option)
* And of course, this file: `system/request.lua`

--]]

-- The action parameter of the request.
local requestAction = GetParam("action") or wikiDefaultAction

local actionParsed = wikiActions[requestAction]

if not actionParsed then
	if requestAction ~= wikiDefaultAction then
		local redirectPath = wikiAbsoluteBase .. (GetPath():sub(2))
		-- print(redirectPath)
		ServeRedirect(303, redirectPath)
		return
	end
end

-- resolve page

local requestPath, requestExt = wikiResolvePage(GetPath())

-- auth checks

if actionParsed.mutator and wikiReadOnly then
	-- @lexisother wins the "first security vuln found" award!
	-- read-only wikis should not be exposing preview; or even the editor at all, really.
	wikiAST.serveRender(WikiTemplate("system/index/frame", {
		title = {"Can't edit: ", wikiTitleStylize(requestPath)},
		parentPath = requestPath,
		path = "system/templates/roError",
		props = {}
	}))
	return
end

if wikiAuthCheckThenRenderFail(actionParsed.action, requestPath) then
	return
end

-- execute

local code, err = wikiRead(actionParsed.path)
assert(code, err)
local actionFn, actionFnErr = load(code, actionParsed.path, "t")
assert(actionFn, actionFnErr)
actionFn(requestPath, requestExt)
