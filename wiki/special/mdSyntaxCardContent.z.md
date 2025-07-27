1. ### The Inline Parable

	<!-- The Zeroth Parable: You cannot outrun your own shadow. -->

	Consider that [the parser here](system/extensions/render/md) is a mess.
	Capable of calculating <?lua 6 * 7 ?>,
		yet a space must always precede the ending of an HTML tag like <br />.
	__When you know why,__ you learn the _balance_ between *`correctness`* and **living.**
	Knowing this, does \`<system/extensions/render/md>\` frighten you?
	The difference between `<div>` and `<div >` means the world now; not without reason.

2. ### The Parable Of Headings

	Only `# these` headings are supported, though of any level.

	Retroactively assigning paragraph text to a heading,
	for a harder-to-type result, feels unnecessary.

3. ### The Parable Of Lines-And-Star

	Paragraphs should be broken by empty lines.
	* But block syntax is more important.
		Line breaks are always hard, such is life.
	*Indentation matters.*

4. ### The Parable Of Lists

	 * While we're not CommonMark compliant, so it appears to say,
	* These are different lists,
		* For the indentation of the second's point is less than that of the first.

5. ### The Parable Of Image-Template-Equivalence

	In what way isn't this an image?

	![](system/templates/recursion)

	And in what way is this different: \[![](system/templates/recursion)\] ?

6. ### The Parable Of Teeth

	Rows of teeth come in many forms; always three or more, not always interspaced, all alike.

	 - - -
	 * * *
	****
	  ****

7. ### The Parable Of Fences

	Only one kind of code-fence is supported.

	```lua
	[=[Inline code of this form can hyperlink globals, such as ]=] .. wikiDefaultExt .. "."
	```

	```md
	_As a general file extension, Markdown is rendered._
	```

	```t.md
	_However, in a code block, a t. prefix is mandatory for this behaviour._
	```

	```t.lua
	local props, renderOptions = ...
	return h("p", {}, table.concat({"With", "this,", "render", "anything", "in",
	(props.fromStartMD or "these unknown lands") .. "."}, " "))
	```

8. ### The Parable Of Recursion

	```t.lua
	return WikiTemplate("system/templates/recursion",
	{ parableMessage = " But it also, in this moment, demonstrates template invocation." })
	```
