## Test double for a View that exposes a context, as GameUiService polls it.
extends Control


class Context extends RefCounted:
	var value := 0


var context: RefCounted
