#!/usr/bin/env lua

-- The author disclaims copyright to this source code.

--[[[
# lhex
View a file as hex in the terminal.

## Install
`luarocks install ers35/lhex`

## Dependencies
- [TermFX](http://tset.de/termfx/index.html)

## Usage
```
usage: lhex [file]
keys:
  Q: Quit
  H: Show this help
  Down Arrow: Move down one row
  Up Arrow: Move up one row
  Page Down: Move down one screen
  Page Up: Move up one screen
  Home: Move to the beginning of the file
  End: Move to the end of the file
```
--]]

local termfx = require("termfx")

local usage = [[
usage: lhex [file]
keys:
  Q: Quit
  H: Show this help
  Down Arrow: Move down one row
  Up Arrow: Move up one row
  Page Down: Move down one screen
  Page Up: Move up one screen
  Home: Move to the beginning of the file
  End: Move to the end of the file
]]

local input = arg[1]
if not input then
	local version = "0.0.1-dev"
	io.stderr:write("lhex ", version, "\n")
	io.stderr:write(usage)
	os.exit(1)
end

local file = io.open(input, "r")
if not file then
	io.stderr:write("File not found: ", input, "\n")
	os.exit(1)
end

local function width()
	return math.ceil(termfx.width() / 3)
end

local function height()
	return termfx.height()
end

local function last()
	return math.max(file:seek("end") - width() * height(), 0)
end

local offset = 0
local help = false

local function draw()
	termfx.clear()
	
	file:seek("set", offset)
	local str = file:read(width() * height())
	if str then
		local x = 1
		local y = 1
		for char in str:gmatch(".") do
			local hexchar = ("%02x"):format(char:byte())
			termfx.printat(x, y, hexchar)
			x = x + 3
			if x >= termfx.width() then
				x = 1
				y = y + 1
				if y > termfx.height() then
					break
				end
			end
		end
	end
	
	if help then
		termfx.rect(1, 1, termfx.width(), termfx.height())
		local x = 1
		local y = 1
		for char in usage:gmatch(".") do
			if char == "\n" then
				x = 1
				y = y + 1
			else
				termfx.printat(x, y, char)
				x = x + 1
			end
		end
	end
	
	termfx.present()
end

termfx.init()
termfx.clear()
local quit = false
local ok, err = pcall(function()
	repeat
		draw()
		local event = termfx.pollevent()
		if event.type == "key" then
			local char = event.char
			local key = event.key
			if char == "q" or key == termfx.key.CTRL_C or key == termfx.key.ESC then
				quit = true
			elseif char == "h" or char == "?" then
				help = not help
			elseif char == "d" then
				dump()
			elseif key == termfx.key.HOME then
				offset = 0
			elseif key == termfx.key.END then
				offset = last()
			elseif key == termfx.key.ARROW_UP then
				offset = offset - width()
			elseif key == termfx.key.ARROW_DOWN then
				offset = offset + width()
			elseif key == termfx.key.ARROW_LEFT then
				offset = offset - 1
			elseif key == termfx.key.ARROW_RIGHT then
				offset = offset + 1
			elseif key == termfx.key.PGUP then
				offset = offset - (width() * height())
			elseif key == termfx.key.PGDN then
				offset = offset + (width() * height())
			end
		end
		-- Constrain offset bounds.
		if offset < 0 then
			offset = 0
		elseif offset > last() then
			offset = last()
		end
	until quit
end)
termfx.shutdown()
file:close()
if not ok then
	io.stderr:write(err, "\n")
	os.exit(1)
end
