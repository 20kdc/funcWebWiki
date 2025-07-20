-- Loads and executes a template for less awkward code.
local function wikiTemplate(template, opts, ...)
	return wikiLoadTemplate(template, ...)(opts or {})
end
return wikiTemplate
