# Plans / Development philosophy / etc.

## `kernel/`

1. Making any more breaking changes to the `kernel/` is probably not necessary.
2. Changes to `kernel/` that improve it in a specific use-case without breaking use outside of that use-case are nice.
3. The job of `kernel/` is to, wherever possible, isolate the wiki from where and how the wiki is hosted.

## `wiki/`

1. Until the end of time, the languages in the base distribution are:
	* Raw `html`
	* `lua` for code display
	* A _lightly_ extended Markdown (images-as-template-invocations, `.t.lua` code blocks)
2. Optional features should be kept rather limited and removal instructions should be indexed here.
	* All triggers can be safely deleted, though they do exist for a reason.
	* The 'system hashes' feature can be removed by:
		* Deleting `system/trigger/updateSystemHashes` and `system/hashes`
		* Reverting `special/systemPages` to use `system/templates/dir`
	* The following pages are leaf pages that can be (more-or-less) harmlessly deleted:
		* `special/mdSyntaxCard`
		* `special/systemPages`
		* `special/missingPages`
		* `special/unreferencedPages`
		* `Start`
		* `system/action/backlinks`
		* `system/action/graphviz`
		* `system/templates/recursion`
		* All 'directory information' pages
			* `system/action`
			* `system/actionName`
			* `system/cache`
			* `system/extensions/code`
			* `system/extensions/mime`
			* `system/extensions/render`
			* `system/index`
			* `system/lib`
			* `system/pageTitle`
			* `system/templates`
			* `system/trigger`
		* All 'translation assist' pages, within:
			* `system/actionName`
			* `system/pageTitle`
3. `system/extensions` is laid out the way it is to allow for adding files without changing anything.
4. Making backlinks scale further will require horrible sacrifices.
	* Perhaps bulldozing the current link cache system in favour of a single 'global link cache' file might be okay.
		* I'm still expecting unforeseen consequences on the sync end, but as long as it's a cache file and it gets deleted on corruption it'll be okay. The cleaner filesystem would be nice.

## Cache Coherence

In order to keep the link cache reasonably coherent yet fast (along with, potentially, browser caching of raw files i.e. media), despite not having a way to perform atomic operations on cache data, it is necessary to take some awkward measures.

The assumptions are:

1. Only one user is editing the wiki at a time, and their edit requests do not overlap.
2. Git/sync operations are also edits. Git/sync operations may or may not ignore the cache entirely.
3. Any operation that changes a file changes the result of any of `stat:mtim()`, `stat:ino()`, or `stat:size()`.
4. Edits are atomic (`kernel.lua` ensures this through move-replace)

Based on these primitives, `kernel.lua` provides a _semi-reliable_ opaque 'file stamp' primitive, `wikiReadStamp` (returns `size, stamp, error`).

The hope is that as long as reading the stamp _before_ reading the contents will at worst result in an outdated stamp, the cache won't go too out-of-sync.

On wikis being read from Redbean assets, due to ZIP file limitations, this primitive returns an empty string if the file exists, and fails if it doesn't.

In this case wiki code must either regenerate on each access or trust that the current cache contents are accurate.

## The Context

The particular problem that got me started on this mess basically amounts to a relatively large address book.

But without some level of templating, changes to the visual structure had to be propagated, somehow; and easily available portable wiki software just isn't up to that kind of templating, except for TiddlyWiki.

Sadly, TiddlyWiki has two key problems:

1. Being designed as a single-file-wiki first makes backup awkward at best, and I find it somewhat alarming that the _existence of multiple tabs_ is dangerous and can lead to reversion on many savers.
   * From some later testing, TiddlyWiki5's Node.js variant in 'server edition' solves some of these problems. However, needing to press `Get latest changes from the server` on all tabs after an edit or risk losing a previous edit if you edit a Tiddler again on a different tab (as yet untested: how do tags play into this?).
2. TiddlyWiki5 involves, simply put, _layers_ of custom language, i.e. filter language, action language, template language.

By opposition:

* funcWebWiki sacrifices serverless in-browser operation for a directory-of-files-first model. Redbean's portability gets it pretty far on modern hardware; lack of 32-bit platform support is the largest hole in the support story, and my testing seems to indicate the `qemu` performance isn't noticably bad except during error sweeps. (A port to another web server is also possible.)
* Editing session conflict between two different tabs exists as with any 'naive' client/server wiki, but for a single user that actually requires they be editing the same page at two places at the same time, not simply having two places at the same time existing and then executing an edit on one, then the other.
* It has some file naming conventions and some custom Markdown semantics, but wherever possible the answer is Lua.
