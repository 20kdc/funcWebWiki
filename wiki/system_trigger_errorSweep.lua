-- Tests to ensure that viewing pages never causes errors.
for _, v in ipairs(wikiPathList()) do
	local template = WikiTemplate(v)
	wikiAST.render(function () end, template, { disableErrorIsolation = true })
	wikiAST.render(function () end, template, { renderType = "renderPlain", disableErrorIsolation = true })
	wikiAST.render(function () end, template, { renderType = "visit", disableErrorIsolation = true })
end
