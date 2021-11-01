#!/usr/bin/lua5.3
-- Replace the Lua version if required

------------
-- Config --
------------

-- Maximum amount of entries allowed on a search, set to nil for no limit
local entryLimit = 50

----------
-- Code --
----------

-- Install this library to the Lua path
local json = require("rxi-json")

-- Base AUR URL
local base_url = "https://aur.archlinux.org"

-- Some ANSI colors for pretty output if the output is a tty or if the NO_COLOR env variable is not set
-- Detect if stdout is a tty from RosettaCode
do
	local ok, exit, signal = os.execute("test -t 1")
	local isatty = ((ok and exit == "exit") and signal == 0 or false)
	local no_color = os.getenv("NO_COLOR")

	if (no_color) or (not isatty) then
		c = {blue="",cyan="",normal=""}
	else
		c = {
			blue = "\027[1;34m",
			cyan = "\027[1;36m",
			normal = "\027[0m"
		}
	end
end

-- From the Programming in Lua book, escape an URL
function escape(s)
	s = string.gsub(s, "([&=+%c])", function (c)
		return string.format("%%%02X", string.byte(c))
	end)
	s = string.gsub(s, " ", "+")
	return s
end

-- Make an http request, requires curl because normal https requests are a pain
function request(url)
	local f = io.popen("curl -sL '"..url.."'")
	local r = f:read("*a")
	f:close()
	return r
end

-- Pretty print every value of a table as a csv
function plist(t)
	for i=1, #t do
		if (i < #t) then
			io.write(t[i],", ")
		else
			io.write(t[i],"\n")
		end
	end
end

-- Search the AUR for a term, filters by name and description
function searchAUR(term)
	print("Searching for "..term.."...\n")
	-- Make a request to the AUR RPC
	local result = request(base_url.."/rpc/?v=5&type=search&by=name-desc&arg="..escape(term))

	local r = json.decode(result)

	-- Pretty print the relevant parts of the JSON
	if (r.resultcount>0) then
		for i=1, math.min(r.resultcount, (entryLimit or r.resultcount)) do
			local rr = r.results[i]
			io.write(c.cyan,(rr.Maintainer or "unknown"),c.normal,"/",c.blue,(rr.Name or "unknown"),c.normal,"\n",
			(rr.Description or "No description"),"\n",
			c.blue,"https://aur.archlinux.org/",rr.Name,".git",c.normal,"\n\n")
		end
	else
		-- If nothing was found, inform the user, exit status 1 for correctness and script integration
		print("Couldn't find what you are looking for")
		os.exit(1)
	end
end

-- Get detailed information about a program in the AUR, the name must be exact
function infoAUR(program)
	print("Getting information about "..program.."...\n")
	-- Send an info request to the AUR RPC
	local result = request(base_url.."/rpc/?v=5&type=info&arg[]="..escape(program))
	if (result ~= '') then
		local r = json.decode(result)

		-- Inform the user if necessary
		if (r.resultcount == 0) then
			print("Couldn't find the package")
			os.exit(1)
		end

		-- Pretty print the JSON received
		local rr = r.results[1]

		-- Maintainer, description and version
		io.write(c.cyan, (rr.Maintainer or "unknown"), c.normal, "/", c.blue, (rr.Name or "unknown"), c.normal, "\n",
		(rr.Description or "No description"), "\n\n",
		c.blue, "Version ", c.cyan, rr.Version, c.normal,"\n")

		-- Print compilation dependencies if available
		if (rr.MakeDepends) then
			io.write("\n",c.blue, "Compilation dependencies", c.normal, "\n")
			plist(rr.MakeDepends)
		end

		-- Print dependencies if available
		if (rr.Depends) then
			io.write("\n",c.blue, "Dependencies", c.normal, "\n")
			plist(rr.Depends)
		end

		-- Print optional dependencies if available
		if (rr.OptDepends) then
			io.write("\n",c.blue, "Optional dependencies", c.normal, "\n")
			plist(rr.OptDepends)
		end

		-- Print licensing information if available
		if (rr.License) then
			io.write("\n",c.blue, "License(s)", c.normal, "\n")
			plist(rr.License)
		end

		-- Inform the user if the package provides executables
		if (rr.Provides) then
			io.write("\n",c.blue, "Provides", c.normal, "\n")
			plist(rr.Provides)
		end

		-- Inform the user if the package conflicts with other packages
		if (rr.Conflicts) then
			io.write("\n",c.blue, "Conflicts", c.normal, "\n")
			plist(rr.Conflicts)
		end

		-- Print the keywords of the given program, good for discovering new packages
		if (rr.Keywords) then
			io.write("\n",c.blue, "Keywords", c.normal, "\n")
			plist(rr.Keywords)
		end

		-- The fundamental git clone URL with the PKGBUILD
		io.write("\n",c.blue, "Clone URL: ",c.cyan,"https://aur.archlinux.org/",rr.Name,".git",c.normal,"\n")
	else
		-- Inform the user if the info command failed
		print("No matches found")
		os.exit(1)
	end
end

-- If the user has a typo, this pops up
function usage()
	print([[
Zap - lightning fast AUR searcher

Usage:
	'zap search string' to search for a term
	'zap string' to search for a term
	'zap info program' to get information on a program
]])
end

-- Parse command line arguments
if (arg[2]) then
	if (arg[1]=="info") then
		infoAUR(arg[2])
	elseif (arg[1]=="search") then
		searchAUR(arg[2])
	else
		usage()
	end
elseif (arg[1]) then
	searchAUR(arg[1])
else
	usage()
end
