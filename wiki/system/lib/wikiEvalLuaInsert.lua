-- Evaluates <?lua ?> code.
return function (contents, code, path, props, renderOptions)
	local v1, v2 = load("local props, renderOptions = ... return " .. code)
	if not v1 then
		table.insert(contents, h("code", {}, tostring(v2)))
	else
		v1, v2 = wikiPCall(v1, props, renderOptions)
		if not v1 then
			table.insert(contents, h("code", {}, tostring(v2)))
		else
			table.insert(contents, v2)
		end
	end
end
