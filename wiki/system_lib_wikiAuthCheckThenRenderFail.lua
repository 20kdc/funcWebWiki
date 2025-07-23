-- This function has the reverse sense of <system/lib/wikiAuthCheck>; it returns true on failure to auth.
-- This is because the caller should immediately return; it's an 'was handled here, so stop now' check.
return function (...)
	if not wikiAuthCheck(...) then
		local action, path = ...
		SetHeader("Content-Type", "text/html")
		wikiAST.serveRender(WikiTemplate("system/index/frame", {
			title = wikiTitleStylize(path),
			path = "system/templates/authError",
			props = { action = action, path = path }
		}))
		return true
	end
	return false
end
