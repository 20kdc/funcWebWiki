local opts = ...

-- beware!

return {
	WikiLink(opts.path, {
		h("input", {type="submit", name="confirm", value="Delete " .. opts.path})
	}, "delete", "formPost")
	-- <system/action/delete>
}
