local props, renderOptions = ...
return h("div", {class="editor2pane"}, {
	WikiTemplate("special/mdSyntaxCardContent", props, true),
	h("div", {}, {
		WikiTemplate("special/mdSyntaxCardContent", props, false)
	})
})
