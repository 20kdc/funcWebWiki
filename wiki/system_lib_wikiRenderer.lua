--[[

A renderer receives (path, code, opts) and returns a <system/lib/wikiAST> node.

These options are defined:

* `title`: The title of the page.
* `path`: The path of an 'interior' page. Where reasonable, templates should support passing a function here; see <system/lib/WikiTemplate>'s response to non-string paths.
* `opts`: The options of an 'interior' page.
* `parentPath`: Received by <system/index/frame> to replace a global variable that was causing linking issues.
  Also used by the md-renderer (and presumably will be by anything doing anything similar) to pass the parent page down to a template such as <system/templates/dir>.
* `opts.pageList`: Used by <system/templates/sortedPageList> only.
* `code`: <system/templates/editor> uses this for the current editing state.
* `alt`: Alt-text contents of an image.
* `inline`: The renderer should prefer to render 'inline' (i.e. inside a paragraph) if possible.
* `linkGen`: Signals that link cache generation is running.

In calls from actions or something like <system/index/frame>, it isn't necessary to inherit options (the former have nothing to inherit, the latter has a dedicated options table to pass).

_However,_ in code such as the md-renderer, options absolutely should be being inherited.

--]]

local rendererCache = {}

local function wikiRenderer(templateExt, promiseThisIsText)
	local function lastResortRenderer(path, code, opts)
		if promiseThisIsText or (wikiExtToMime(templateExt) or ""):sub(1, 5) == "text/" then
			return h("pre", {}, code)
		else
			return WikiLink(path, { opts.alt or wikiTitleStylize(path) }, "raw", "image")
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
				renderer = renderer or function (path, code, opts)
					return {
						h("p", {}, "Renderer " .. rendererPath .. " could not be loaded."),
						h("pre", {}, tostring(err)),
						lastResortRenderer(path, code, opts)
					}
				end
				break
			end
		end
		renderer = renderer or lastResortRenderer
		rendererCache[templateExt] = renderer
	end
	return renderer
end

return wikiRenderer
