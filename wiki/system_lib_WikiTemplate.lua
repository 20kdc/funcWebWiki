-- _This is styled like a component because might get converted to be one._
-- All pages are 'templates'.
-- Thus WikiTemplate loads a page for rendering.
-- The resulting functions are passed the options table.
-- Notably, if WikiTemplate is passed something other than a string, it is returned directly. The idea behind this is to allow passing anonymous templates.

local templateCache = {}
local templateHighlightCache = {}

local function wikiLoadTemplate(template, codeFlag)
	if type(template) ~= "string" then
		return template
	end

	local cache = templateCache
	if codeFlag then
		cache = templateHighlightCache
	end
	local templatePath, templateExt = wikiResolvePage(template)
	if cache[templatePath] then
		return cache[templatePath]
	end
	local code, codeErr = wikiRead(templatePath)
	if not code then
		local res
		if template == "system/templates/missingTemplate" then
			-- system/templates/missingTemplate has a fallback to prevent recursion
			res = function (opts)
				-- <system/action/w/edit>
				local nameChunk = tostring(opts.path)
				if wikiAuthCheck(nameChunk, "w/edit") and not wikiReadOnly then
					nameChunk = WikiLink(nameChunk, nil, "w/edit")
				end
				return {
					"(",
					nameChunk,
					" missing)"
				}
			end
		else
			-- so the order proceeds:
			-- system/{template}
			-- system/templates/missingTemplate
			-- (built-in)
			local missingTemplate = wikiLoadTemplate("system/templates/missingTemplate")
			res = function (opts)
				return missingTemplate({
					path = templatePath,
					opts = opts
				})
			end
		end
		cache[templatePath] = res
		return res
	end
	if codeFlag then
		local repExt = nil
		for ext in wikiExtIter(templateExt) do
			repExt = wikiReadConfig("system/extensions/code/" .. ext .. ".txt", nil)
			if repExt then
				break
			end
		end
		templateExt = repExt or wikiDefaultCodeExt
	end
	local renderer = wikiRenderer(templateExt)
	local res = function (opts)
		return renderer(templatePath, code, opts)
	end
	cache[templatePath] = res
	return res
end

-- Loads and executes a template for less awkward code.
local function WikiTemplate(template, opts, ...)
	return wikiLoadTemplate(template, ...)(opts or {})
end

return WikiTemplate
