-- 'Execute' action. Must be POST.
local requestPath, requestExt = ...

-- This should implicitly stop the execute verb from being used to scam more secure action types.
-- That said, it might be an idea to restrict this to <system/action> entirely.
if GetMethod() == "POST" and (GetParam("confirm") or "") ~= "" then
	assert(requestExt == "lua", "execute cannot be used on a file without a pure 'lua' extension")
	dofile(requestPath)
	return
end

return wikiAST.serveRender(WikiTemplate("system/index/frame", {
	title = {"Execute ", wikiTitleStylize(requestPath), "?"},
	parentPath = requestPath,
	path = "system/templates/prompt",
	props = {
		text = ("Execute " .. requestPath),
		path = EncodeUrl({path = requestPath, params = GetParams()})
	}
}))
