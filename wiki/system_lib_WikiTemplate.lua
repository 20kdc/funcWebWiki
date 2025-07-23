-- All pages are 'templates'.
-- Thus the WikiTemplate component wraps a page in a renderer.
-- Notably, if the template path is something other than a string, it is returned directly.
-- The idea behind this is to allow passing anonymous templates.

-- Functions in this table are cached templates, passed (props, renderOptions).
-- While this doesn't save reparsing (reuse per-request isn't high enough to justify making the renderer code much more complex), it does save reloading.
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
	local useMarker = WikiDepMarker(templatePath)
	local code, codeErr = wikiRead(templatePath)
	if not code then
		local res
		if template == "system/templates/missingTemplate" then
			-- system/templates/missingTemplate has a fallback to prevent recursion
			res = function (props, renderOptions)
				-- <system/action/edit>
				local nameChunk = tostring(props.path)
				if renderOptions.disableErrorIsolation then
					error(nameChunk .. " is missing")
				end
				if wikiAuthCheck(nameChunk, "edit") and not wikiReadOnly then
					nameChunk = WikiLink(nameChunk, nil, "edit")
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
			res = function (props, renderOptions)
				return missingTemplate({
					path = templatePath,
					props = props
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
	local res = function (props, renderOptions)
		-- This wrapper can do various theoretical things.
		-- In practice it's responsible for making sure that invoked templates are dependencies.
		-- Renderers are not considered so, because that line of thinking leads to pretty much all of system/ being a dependency.
		return {
			useMarker,
			renderer(templatePath, code, props, renderOptions)
		}
	end
	cache[templatePath] = res
	return res
end

local function conditionalErrorHandler(ok, res, where, renderOptions)
	if ok then
		return res
	end
	if renderOptions.disableErrorIsolation then
		error(where .. "\n" .. tostring(res))
	else
		return h("pre", {}, tostring(res))
	end
end

-- Loads and executes a template for less awkward code.
return wikiAST.newClass({
	visit = function (self, writer, renderOptions)
		-- render template content to res
		local ok, res = wikiPCall(self.template, self.props, renderOptions)
		local templatedContent = conditionalErrorHandler(ok, res, "Template <" .. tostring(self.templatePath) .. "> execute:", renderOptions)
		ok, res = wikiPCall(wikiAST.render, writer, templatedContent, renderOptions)
		-- should return nil if all went well
		res = conditionalErrorHandler(ok, res, "Template <" .. tostring(self.templatePath) .. "> render:", renderOptions)
		if res then
			wikiAST.render(writer, res, renderOptions)
		end
	end
}, function (self, template, props, ...)
	return setmetatable({
		templatePath = template,
		template = wikiLoadTemplate(template, ...),
		props = props or {}
	}, self)
end)
