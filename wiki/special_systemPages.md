System pages make up most of the code of the wiki.

Because there's a _lot_ of them and they aren't relevant except when customizing the wiki, they're not shown in the navigation panel.

```t.lua
return wikiTemplate("system/templates/sortedPageList", {pageList = wikiPathList("system/")})
```
