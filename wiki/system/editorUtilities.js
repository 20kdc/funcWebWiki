var editor = document.getElementById("editor");
if (editor) {
	editor.onkeydown = function (ev) {
		// console.log("debug", ev);
		if (ev.key == "Tab" && !ev.shiftKey) {
			// indent
			var repl = editor.value.substring(editor.selectionStart, editor.selectionEnd);
			// 🎸 what is this code lollll
			repl = (("\n" + repl)).replaceAll("\n", "\n\t").substring(1);
			var mode = editor.selectionStart == editor.selectionEnd ? "end" : "preserve";
			editor.setRangeText(repl, editor.selectionStart, editor.selectionEnd, mode);
			ev.preventDefault();
		} else if (ev.key == "Tab" && ev.shiftKey) {
			// unindent.
			var repl = editor.value.substring(editor.selectionStart, editor.selectionEnd);
			repl = (("\n" + repl)).replaceAll("\n\t", "\n").substring(1);
			var mode = editor.selectionStart == editor.selectionEnd ? "end" : "preserve";
			editor.setRangeText(repl, editor.selectionStart, editor.selectionEnd, mode);
			// console.log("debug", ev);
			ev.preventDefault();
		}
	};
	document.addEventListener("DOMContentLoaded", function () {
		window.editorLineSpan = document.getElementById("editorLineSpan");
		window.editorLivePreview = document.getElementById("editorLivePreview");
		if (editorLivePreview) {
			window.editorLPRequestDebounceCode = editor.value;
			window.editorLPXHR = new XMLHttpRequest();
		}
		setInterval(function () {
			if (editorLivePreview) {
				if (editorLPXHR.readyState == 0 || editorLPXHR.readyState == 4) {
					if (editorLPXHR.readyState == 4) {
						editorLivePreview.innerHTML = editorLPXHR.responseText;
					}
					if (editorLPRequestDebounceCode != editor.value) {
						editorLPRequestDebounceCode = editor.value;
						var url = editorLivePreview.attributes["data-xhr"].value;
						editorLPXHR.open("POST", url, true);
						editorLPXHR.send(editor.value);
					}
				}
			}
			if (editorLineSpan) {
				var lineMatch = editor.value.substring(0, editor.selectionStart).match(/\n/g);
				var lineNumber = (lineMatch || []).length + 1;
				editorLineSpan.innerText = "" + lineNumber;
			}
		}, 100);
	});
}
var fileshunt = document.getElementById("fileshunt");
if (fileshunt) {
	var fileinput = document.getElementById("fileinput");
	var filestatus = document.getElementById("filestatus");
	fileinput.addEventListener("change", function () {
		fileshunt.value = "";
		filestatus.value = "Please wait...";
		if (fileinput.files[0]) {
			var fr = new FileReader();
			fr.addEventListener("loadend", function () {
				fileshunt.value = fr.result;
				filestatus.value = "Upload";
			}, true);
			fr.readAsDataURL(fileinput.files[0]);
		} else {
			filestatus.value = "No file";
		}
	}, true);
}
