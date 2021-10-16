#!/usr/bin/lua5.3
-- Replace the Lua version if required

local json = require("rxi-json")

local base_url = "https://aur.archlinux.org"

local c = {
	blue = "\027[1;34m",
	cyan = "\027[1;36m",
	normal = "\027[0m"
}

-- From the Programming in Lua book
function escape(s)
	s = string.gsub(s, "([&=+%c])", function (c)
		return string.format("%%%02X", string.byte(c))
	end)
	s = string.gsub(s, " ", "+")
	return s
end

function request(url)
	local f = io.popen("curl -sL '"..url.."'")
	local r = f:read("*a")
	f:close()
	return r
end

function plist(t)
	for i=1, #t do
		if (i < #t) then
			io.write(t[i],", ")
		else
			io.write(t[i],"\n")
		end
	end
end

function searchAUR(term)
	print("Searching for "..term.."...\n")
	local result = request(base_url.."/rpc/?v=5&type=search&by=name-desc&arg="..escape(term))

	local r = json.decode(result)

	if (r.resultcount>0) then
		for i=1, r.resultcount do
			local rr = r.results[i]
			io.write(c.cyan,(rr.Maintainer or "unknown"),c.normal,"/",c.blue,rr.Name,c.normal,"\n",
			rr.Description,"\n",
			c.blue,"https://aur.archlinux.org/",rr.Name,".git",c.normal,"\n\n")
		end
	else
		print("Couldn't find what you are looking for")
		os.exit(1)
	end
end

function infoAUR(program)
	print("Getting information about "..program.."...\n")
	local result = request(base_url.."/rpc/?v=5&type=info&arg[]="..escape(program))
	if (result ~= '') then
		local r = json.decode(result)

		if (r.resultcount == 0) then
			print("Couldn't find the package")
			os.exit(1)
		end

		local rr = r.results[1]
		io.write(c.cyan, (rr.Maintainer or "unknown"), c.normal, "/", c.blue, rr.Name, c.normal, "\n",
		rr.Description, "\n\n",
		c.blue, "Version ", c.cyan, rr.Version, c.normal,"\n")

		if (rr.MakeDepends) then
			io.write("\n",c.blue, "Compilation dependencies", c.normal, "\n")
			plist(rr.MakeDepends)
		end

		if (rr.Depends) then
			io.write("\n",c.blue, "Dependencies", c.normal, "\n")
			plist(rr.Depends)
		end

		if (rr.OptDepends) then
			io.write("\n",c.blue, "Optional dependencies", c.normal, "\n")
			plist(rr.OptDepends)
		end

		if (rr.License) then
			io.write("\n",c.blue, "License(s)", c.normal, "\n")
			plist(rr.License)
		end

		if (rr.Provides) then
			io.write("\n",c.blue, "Provides", c.normal, "\n")
			plist(rr.Provides)
		end

		if (rr.Conflicts) then
			io.write("\n",c.blue, "Conflicts", c.normal, "\n")
			plist(rr.Conflicts)
		end

		if (rr.Keywords) then
			io.write("\n",c.blue, "Keywords", c.normal, "\n")
			plist(rr.Keywords)
		end

		io.write("\n",c.blue, "Clone URL: ",c.cyan,"https://aur.archlinux.org/",rr.Name,".git",c.normal,"\n")
	else
		print("No matches found")
		os.exit(1)
	end
end

function usage()
	print([[
Zap - lightning fast AUR searcher

Usage:
	'zap search string' to search for a term
	'zap string' to search for a term
	'zap info program' to get information on a program
]])
end

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
