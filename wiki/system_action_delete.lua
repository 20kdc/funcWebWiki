-- Editor action.
if (GetParam("confirm") or "") ~= "" then
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
