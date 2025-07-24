var editor = document.getElementById("editor");
if (editor) {
	editor.onkeydown = function (ev) {
		if (ev.key == "Tab") {
			editor.setRangeText("\t", editor.selectionStart, editor.selectionEnd, "end");
			// console.log("debug", ev);
			ev.preventDefault();
		}
	}
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
