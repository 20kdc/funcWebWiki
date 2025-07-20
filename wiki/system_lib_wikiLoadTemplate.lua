--[[

All pages are 'templates'.

Thus wikiLoadTemplate loads a page for rendering.

The resulting functions are passed the options table.

--]]

local templateCache = {}

local function wikiLoadTemplate(template)
	local templatePath, templateExt = wikiResolvePage(template)
	if templateCache[templatePath] then
		return templateCache[templatePath]
	end
	local code, codeErr = Slurp(templatePath)
	if not code then
		local res
		if template == "system/templates/missingTemplate" then
			-- system/templates/missingTemplate has a fallback to prevent recursion
			res = function (opts)
				return {
					"(",
					h("a", {href = tostring(opts.path) .. "?action=edit"},
						tostring(opts.path)
					),
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
		templateCache[templatePath] = res
		return res
	end
	local renderer = wikiRenderer(templateExt)
	local res = function (opts)
		return renderer(templatePath, code, opts)
	end
	templateCache[templatePath] = res
	return res
end

return wikiLoadTemplate
