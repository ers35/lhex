default: readme.md

readme.md: lhex.lua Makefile
	lua -e 'for match in io.read("*all"):gmatch("--%[%[%[%s?(.-)--%]%]") do print(match) end' < "$<" > "$@"
