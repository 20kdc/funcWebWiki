-- Confirm deleting the file; if the confirm parameter is given, do it.

if wikiAuthCheckThenRenderFail("delete", wikiRequestPath) then
	return
end

if GetMethod() == "POST" and (GetParam("confirm") or "") ~= "" then
	-- yes, we're sure
	wikiDelete(wikiRequestPath)
	ServeRedirect(303, wikiAbsoluteBase .. wikiRequestPath)
	return
end

wikiAST.render(Write, wikiTemplate("system/templates/frame", {
	title = {"Delete ", wikiTitleStylize(wikiRequestPath), "?"},
	path = "system/templates/deletePrompt",
	opts = {
		path = wikiRequestPath
	}
}))
