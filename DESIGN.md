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
	* The 'system hashes' feature can be removed by:
		* Deleting `system/trigger/updateSystemHashes` and `system/hashes`
		* Reverting `special/systemPages` to use `system/templates/dir`
	* The following pages are leaf pages that can be harmlessly deleted from the system:
		* `special/systemPages`
		* `special/missingPages`
		* `special/unreferencedPages`
		* `system/action/backlinks`
		* `system/action/graphviz`
		* All 'directory information' pages
			* `system/action`
			* `system/cache`
			* `system/extensions/code`
			* `system/extensions/mime`
			* `system/extensions/render`
			* `system/index`
			* `system/lib`
			* `system/templates`
			* `system/trigger`
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

On wikis being read from Redbean assets, due to ZIP file limitations, this primitive returns an empty string if the file exists, and fails if it doesn't.

In this case wiki code must either regenerate on each access or trust that the current cache contents are accurate.
