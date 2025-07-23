-- Confirm deleting the file; if the confirm parameter is given, do it.

local requestPath, requestExt = ...

if GetMethod() == "POST" and (GetParam("confirm") or "") ~= "" then
	-- yes, we're sure
	wikiDelete(requestPath)
	wikiFlushCacheForPageEdit(requestPath)
	ServeRedirect(303, wikiAbsoluteBase .. requestPath)
	return
end

SetHeader("Content-Type", "text/html")

wikiAST.serveRender(WikiTemplate("system/index/frame", {
	title = {"Delete ", wikiTitleStylize(requestPath), "?"},
	parentPath = requestPath,
	path = "system/templates/deletePrompt",
	props = {
		path = requestPath,
		ext = requestExt
	}
}))
