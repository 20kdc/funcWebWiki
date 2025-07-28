--[[

A renderer receives (path, code, props, renderOptions) and returns a <system/lib/wikiAST> node.

The following list gives 'global' prop names (tend to appear everywhere).
Case-specific props are no longer listed as such a list is difficult to maintain.

* `parentPath`: Used by the md-renderer to pass the parent page down to a template such as <system/templates/dir>.
* `alt`: Alt-text contents of an image. May be ignored if empty string.
* `inline`: The renderer should prefer to render 'inline' (i.e. inside a paragraph) if possible.
* `linkGen`: Signals that link cache generation is running. Some templates, particularly expensive ones, might choose to simply not render if this comes up.

For `renderOptions`, please see <system/lib/wikiAST>.

Props should be inherited whenever they are being handled by markup which cannot make its own decisions; so in other words, <system/extensions/render/md> should inherit props.

Other code should use its own judgement on what should be passed through and what shouldn't.

--]]

local rendererCache = {}

local function wikiRenderer(templateExt, promiseThisIsText, codeFlag)
	-- handle codeFlag
	if codeFlag == "codeBlock" then
		codeFlag = templateExt:sub(1, 2) ~= "t."
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

	-- continue...
	local function lastResortRenderer(path, code, props, renderOptions)
		local alt = props.alt
		if alt == "" then
			alt = nil
		end
		local mime = wikiExtToMime(templateExt) or ""
		local mimeS6 = mime:sub(1, 6)
		if promiseThisIsText or mime:sub(1, 5) == "text/" then
			return h("p", {}, h("pre", {}, code))
		else
			-- these are all basically the same
			local linkType = nil
			if mimeS6 == "image/" or mimeS6 == "audio/" or mimeS6 == "video/" then
				linkType = mime:sub(1, 5)
			end
			return h("div", { class = "media-box" },
				WikiLink(path, { alt or wikiTitleStylize(path) }, "raw", linkType)
			)
		end
	end

	local renderer = rendererCache[templateExt]
	local err
	if not renderer then
		for ext in wikiExtIter(templateExt) do
			local rendererPath = "system/extensions/render/" .. ext .. ".lua"
			local rendererCode = wikiRead(rendererPath)
			if rendererCode then
				renderer, err = load(rendererCode, rendererPath)
				renderer = renderer or function (path, code, props, renderOptions)
					return {
						h("p", {}, "Renderer " .. rendererPath .. " could not be loaded."),
						h("pre", {}, tostring(err)),
						lastResortRenderer(path, code, props, renderOptions)
					}
				end
				break
			end
		end
		renderer = renderer or lastResortRenderer
		local rendererOld = renderer
		-- debug validation
		renderer = function (path, code, props, renderOptions)
			assert(type(path) == "string", "path must be string")
			assert(type(code) == "string", "code must be string")
			assert(type(props) == "table", "props must be table")
			assert(type(renderOptions) == "table", "renderOptions must be table")
			if not renderOptions.disableErrorIsolation then
				local ok, res = wikiPCall(rendererOld, path, code, props, renderOptions)
				if not ok then
					res = h("pre", {}, tostring(res))
				end
				return res
			else
				return rendererOld(path, code, props, renderOptions)
			end
		end
		rendererCache[templateExt] = renderer
	end
	return renderer
end

return wikiRenderer
