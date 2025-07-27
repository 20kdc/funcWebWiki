-- All pages are 'templates'.
-- Thus the WikiTemplate component wraps a page in a renderer.
-- Notably, if the template path is something other than a string, it is returned directly.
-- The idea behind this is to allow passing anonymous templates.

-- Table-of-tables [codeFlag][path]
-- Functions in this table are cached templates, passed (props, renderOptions).
-- While this doesn't save reparsing (reuse per-request isn't high enough to justify making the renderer code much more complex), it does save reloading.
local templateCache = {}

--[[
codeFlag can be:
* nil/false: Run normal extension-matching logic.
* true: Lookup in <system/extensions/code>, return "txt".
* "codeBlock": _Extension is assumed to be manually specified._
               If extension begins with "t.", see false. Otherwise, see true.
               This means that, i.e. "t.md" renders Markdown, while "md" would fallback to "txt" (or a set handler).
--]]
local function wikiLoadTemplate(templatePath, templateExt, codeFlag)
	if type(templatePath) ~= "string" then
		return templatePath
	end

	codeFlag = codeFlag or false

	local cache = templateCache[codeFlag]
	if not cache then
		cache = {}
		templateCache[codeFlag] = cache
	end

	if cache[templatePath] then
		return cache[templatePath]
	end
	local useMarker = WikiDepMarker(templatePath)
	local code, codeErr = wikiRead(templatePath)
	if not code then
		local res
		if templatePath:sub(1, 32) == "system/templates/missingTemplate" then
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
				}, renderOptions)
			end
		end
		cache[templatePath] = res
		return res
	end
	local renderer = wikiRenderer(templateExt, false, codeFlag)
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
-- Passed (template, props, ) and then arguments to `wikiLoadTemplate` above.
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
	local templateExt = wikiDefaultExt
	if type(template) == "string" then
		-- catch, i.e. ![](./exampleInvalidLink)
		local original = template
		template, templateExt = wikiResolvePage(template)
		if not template then
			template = wikiResolvePage("system/templates/invalidPathError")
			props = {path = original, inline = true}
		end
	end
	return setmetatable({
		templatePath = template,
		template = wikiLoadTemplate(template, templateExt, ...),
		props = props or {}
	}, self)
end)
