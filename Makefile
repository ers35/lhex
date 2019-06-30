default: readme.md

readme.md: lhex.lua
	doc $< $@
