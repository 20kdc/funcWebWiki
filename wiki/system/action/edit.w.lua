-- Editor action.
-- This must handle text and uploads; uploads are a bit weird here as it seems while Redbean can parse POST payloads, it cannot parse multipart forms.
-- Rather than trying, it is easiest simply to store the payload in base64; all workarounds other than a multipart form parser would involve JavaScript anyway, and this is the simplest.

local requestPath, requestExt = ...

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

local errorMessage = ""
if GetMethod() == "POST" and code and (GetParam("confirm") or "") ~= "" then
	-- confirmed edit; do it
	local writeOk
	writeOk, errorMessage = wikiWrite(requestPath, code)
	if writeOk then
		wikiFlushCacheForPageEdit(requestPath)
		-- This 'post-edit' anchor is a hook used by journal pages in production.
		ServeRedirect(303, wikiAbsoluteBase .. requestPath .. "#post-edit")
		return
	end
end

local preview = not not code
code = code or wikiRead(requestPath)
if preview then
	wikiAST.serveRender(WikiTemplate("system/index/frame", {
		title = {"Editing: ", wikiTitleStylize(requestPath)},
		parentPath = requestPath,
		path = "system/templates/editorAndPreview",
		props = {
			path = requestPath,
			ext = requestExt,
			code = code,
			errorMessage = errorMessage
		}
	}))
else
	wikiAST.serveRender(WikiTemplate("system/index/frame", {
		title = {"Editing: ", wikiTitleStylize(requestPath)},
		parentPath = requestPath,
		path = "system/templates/editor",
		props = {
			path = requestPath,
			ext = requestExt,
			code = code,
			errorMessage = errorMessage
		}
	}))
end
