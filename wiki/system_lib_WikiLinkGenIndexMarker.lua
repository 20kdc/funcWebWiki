-- Special marker object which tells linkGen that this contains embedded indices and should be treated as such.
return wikiAST.newClass({
	renderHtml = function ()
	end,
	renderPlain = function ()
	end
}, function (self)
	return setmetatable({}, self)
end)
