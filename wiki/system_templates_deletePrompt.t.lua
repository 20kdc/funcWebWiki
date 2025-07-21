local opts = ...

-- beware!

return {
	WikiLink(opts.path, {
		h("input", {type="submit", name="confirm", value="Delete " .. opts.path})
	}, "w/delete", "formPost")
	-- <system/action/w/delete>
}
