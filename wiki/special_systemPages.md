System pages make up most of the code of the wiki.

Because there's a _lot_ of them and they aren't relevant except when customizing the wiki, they're not shown in the navigation panel.

Pages which have been changed/added relative to <system/hashes.json> are marked with an asterisk.

```t.lua
return WikiTemplate("system/templates/dir", {parentPath = "system", systemHashCheck = true})
```
