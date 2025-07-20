var editor = document.getElementById("editor");
editor.onkeydown = function (ev) {
	if (ev.key == "Tab") {
		editor.setRangeText("\t", editor.selectionStart, editor.selectionEnd, "end");
		// console.log("debug", ev);
		ev.preventDefault();
	}
}
