-- This function has the reverse sense of <system/lib/wikiAuthCheck>; it returns true on failure to auth.
-- This is because the caller should immediately return; it's an 'was handled here, so stop now' check.
return function (...)
	if not wikiAuthCheck(...) then
		local action, path = ...
		SetHeader("Content-Type", "text/html")
		wikiAST.render(Write, wikiTemplate("system/templates/frame", {
			title = wikiTitleStylize(wikiRequestPath),
			path = "system/templates/authError",
			opts = { action = action, path = path }
		}))
		return true
	end
	return false
end
