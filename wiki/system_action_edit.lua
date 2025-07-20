-- Editor action.
local code = GetParam("code")
if code then
	code = code:gsub("\r", "")
end
if code and (GetParam("confirm") or "") ~= "" then
	-- confirmed edit; do it
	Barf(wikiRequestPath, code)
	ServeRedirect(303, wikiAbsoluteBase .. wikiRequestPath)
	return
end
local preview = not not code
code = code or Slurp(wikiRequestPath)
wikiAST.render(Write, wikiTemplate("system/templates/frame", {
	title = {"Editing: ", wikiTitleStylize(wikiRequestPath)},
	path = "system/templates/editor",
	opts = {
		path = wikiRequestPath,
		code = code,
		preview = preview
	}
}))
