Triggers are used to perform maintenance tasks from the command-line using the `--trigger` option.

They, like the <system/request> handler, are invoked by `kernel.lua`.

They can also be invoked from their respective pages using <system/action/execute>.

(When invoked this way, if a trigger returns a truthy value, it's assumed that the trigger didn't write a response, and a redirect is served.)

They consist of Lua files which are simply executed with `dofile`.

They can usually do anything an action can, but when invoked using `--trigger`, a number of functions are stubbed and will do nothing / return nil:

```lua
SetStatus, SetHeader, ServeRedirect, GetHeader
```

The following functions provide 'useful fakes', and more or less work as expected:

```lua
Write, GetPath, GetParam, GetParams, GetMethod
```

(Note that `GetPath` is left 'intentionally incorrect'; the invoked file is in the trigger directory, but the path given is in the root. This implies external invocation, though in retrospect this is a questionable way of doing it.)

![](system/templates/dir)
