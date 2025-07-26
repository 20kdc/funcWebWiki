--[[

This is the entrypoint called by the 'kernel' for each request.

Here is how things happen there:

First, two rules (that can be controlled from the command-line):
* The request path may be optionally stripped of a prefix, which is replaced with "/".
* `/favicon.ico` is also served from Redbean's `favicon.ico`.

If `WIKI_TWM_PASSWORD` is in the environment, the query parameter `_twm` is checked.
If it is equal to the password, the 'tactical witch mode' editor is served.

Upon each request, a new environment is created, which consists of:

* A large quantity of Redbean and Lua functions.
* `table.assign(target, sources...) -> target`, `table.deepcopy(source) -> copy`
* `wikiRead(path) -> data | nil, err`, `wikiReadStamp(path) -> length, stamp | nil, nil, err`
* `wikiWrite(path, data) -> true | nil, err`, `wikiDelete(path) -> true | nil, err`
* `wikiPathParse(path[, allowNoExt]) -> parsed | nil, err`, `wikiPathUnparse(parsed) -> path`, `wikiPathTable([prefix]) -> paths`, `wikiPathList([prefix]) -> paths`
* `wikiAbsoluteBase`
* `wikiReadOnly` (assets are being read via the Redbean asset system, wiki is fully immutable)

`kernel.lua` looks for the following wiki files:

* <system/lib>: `system/lib/*.lua` (whenever a global is missing)
* <system/trigger>: `system/trigger/*.lua` (the `--trigger` option)
* And of course, this file: `system/request.lua`

--]]

local requestPath = GetPath()

if requestPath:sub(1, 9) == "/_assets/" then
	return ServeAsset(requestPath:sub(9))
end


-- The action parameter of the request.
local requestAction = GetParam("action") or wikiDefaultAction

local actionParsed = wikiActions[requestAction]

if not actionParsed then
	if requestAction ~= wikiDefaultAction then
		local redirectPath = wikiAbsoluteBase .. (requestPath:sub(2))
		-- print(redirectPath)
		ServeRedirect(303, redirectPath)
		return
	end
end

-- resolve page

local requestPathUnfiltered = requestPath
local requestPath, requestExt = wikiResolvePage(requestPath)

if not requestPath then
	wikiAST.serveRender(WikiTemplate("system/index/frame", {
		title = {"Invalid Path"},
		path = "system/templates/invalidPathError",
		props = {path = requestPathUnfiltered}
	}))
	return
end

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

if not wikiAuthCheck(actionParsed, requestPath) then
	wikiAST.serveRender(WikiTemplate("system/index/frame", {
		title = wikiTitleStylize(requestPath),
		path = "system/templates/authError",
		props = { actionParsed = actionParsed, path = requestPath }
	}))
	return
end

-- execute

local code, err = wikiRead(actionParsed.path)
assert(code, err)
local actionFn, actionFnErr = load(code, actionParsed.path, "t")
assert(actionFn, actionFnErr)
actionFn(requestPath, requestExt)
