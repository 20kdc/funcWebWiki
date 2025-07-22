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
