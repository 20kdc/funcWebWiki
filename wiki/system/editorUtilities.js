var editor = document.getElementById("editor");
if (editor) {
	editor.onkeydown = function (ev) {
		if (ev.key == "Tab") {
			editor.setRangeText("\t", editor.selectionStart, editor.selectionEnd, "end");
			// console.log("debug", ev);
			ev.preventDefault();
		}
	};
	document.addEventListener("DOMContentLoaded", function () {
		console.log("starting editor live preview...");
		window.editorLivePreview = document.getElementById("editorLivePreview");
		if (editorLivePreview) {
			window.editorLPRequestDebounceCode = editor.value;
			window.editorLPXHR = new XMLHttpRequest();
			setInterval(function () {
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
			}, 100);
		}
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
