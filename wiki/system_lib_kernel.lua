--[[

The kernel you seek is, in fact, not actually here.

The kernel provides the environment for actions, which consists of:

* A large quantity of Redbean and Lua functions. (`Slurp` and `Barf` are wrapped to operate in-wiki only.)
* `wikiPathParse`, `wikiPathUnparse`, `wikiPathTable`, `wikiPathList`
* `wikiReadConfig`
* `wikiResolvePage`
* `wikiRequestPath`, `wikiRequestAction`, `wikiRequestExtension`
* `wikiAbsoluteBase`

The kernel looks for the following wiki files:

* <system/extensions/default.txt> provides the default extension for `wikiResolvePage`.
* <system/action/default.lua> (actions in general, but particularly that one) is launched.
* `system/lib/*.lua` (whenever a global is missing)

--]]
