-- Editor action.
-- This must handle text and uploads; uploads are a bit weird here as it seems while Redbean can parse POST payloads, it cannot parse multipart forms.
-- Rather than trying, it is easiest simply to store the payload in base64; all workarounds other than a multipart form parser would involve JavaScript anyway, and this is the simplest.

local code = GetParam("code")
if code then
	code = code:gsub("\r", "")
else
	-- upload bypasses newline replacement
	code = GetParam("file") or ""
	local base64Start = code:find("base64,", 1, true)
	if base64Start then
		code = DecodeBase64(code:sub(base64Start + 7))
	else
		code = nil
	end
end

if GetMethod() == "POST" and code and (GetParam("confirm") or "") ~= "" then
	-- confirmed edit; do it
	Barf(wikiRequestPath, code)
	ServeRedirect(303, wikiAbsoluteBase .. wikiRequestPath)
	return
end

SetHeader("Content-Type", "text/html")

local preview = not not code
code = code or Slurp(wikiRequestPath)
if preview then
	wikiAST.render(Write, wikiTemplate("system/templates/frame", {
		title = {"Editing: ", wikiTitleStylize(wikiRequestPath)},
		path = "system/templates/editorAndPreview",
		opts = {
			path = wikiRequestPath,
			code = code
		}
	}))
else
	wikiAST.render(Write, wikiTemplate("system/templates/frame", {
		title = {"Editing: ", wikiTitleStylize(wikiRequestPath)},
		path = "system/templates/editor",
		opts = {
			path = wikiRequestPath,
			code = code
		}
	}))
end
