--[[

All pages are 'templates'.

Thus wikiLoadTemplate loads a page for rendering.

The resulting functions are passed the options table.

--]]

local templateCache = {}
local templateHighlightCache = {}

local function wikiLoadTemplate(template, codeFlag)
	local cache = templateCache
	if codeFlag then
		cache = templateHighlightCache
	end
	local templatePath, templateExt = wikiResolvePage(template)
	if cache[templatePath] then
		return cache[templatePath]
	end
	local code, codeErr = Slurp(templatePath)
	if not code then
		local res
		if template == "system/templates/missingTemplate" then
			-- system/templates/missingTemplate has a fallback to prevent recursion
			res = function (opts)
				return {
					"(",
					WikiLink(tostring(opts.path), nil, "edit"),
					")",
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
		templateExt = wikiReadConfig("system/extensions/code/" .. templateExt .. ".txt", "txt")
	end
	local renderer = wikiRenderer(templateExt)
	local res = function (opts)
		return renderer(templatePath, code, opts)
	end
	cache[templatePath] = res
	return res
end

return wikiLoadTemplate
