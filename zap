#!/usr/bin/luajit

-- Zap, A lightning fast AUR searcher
-- By Bowuigi

search_v = {
	curl = [[ curl -s 'https://aur.archlinux.org/rpc/?v=5&type=search&by=name-desc&arg=%s' ]],
	jq = [[ jq -r '.results | .[] | "%s\(.Maintainer)%s/%s\(.Name)%s\n\(.Description)\n%https://saur.archlinux.org/\(.Name).git%s\n"' ]]
}

info_v = {
	curl=[[ curl -sL 'aur.archlinux.org/rpc/?v=5&type=info&arg[]=%s' ]],
	jq=[[ jq -r '.results[0] | "Package %s\(.Name)%s, version %s\(.Version)%s.\n\(.Description)\nMaintained by %s\(.Maintainer)%s" , "%sLicenses%s\n\(.License | @tsv?)" , "%sDepends on%s\n\(.Depends | @tsv?)" , "%sRequires those for compilation%s\n\(.MakeDepends | @tsv?)" , "%sOptionally depends on%s\n\(.OptDepends | @tsv?)" , "Repo link: %shttps://aur.archlinux.org/\(.Name).git%s"' | tr '\t' ' ' ]]
}

function sh(cmd)
	local f=io.popen(cmd,r)
	local tmp=f:read("*a")
	f:close()
	return tmp
end

function search(package)
	return sh (
		string.format (
			search_v.curl.." | "..search_v.jq,
			package,
			"\027[1;36m",
			"\027[0m",
			"\027[1;34m",
			"\027[0m",
			"\027[1;34m",
			"\027[0m"
		)
	)
end

function info(package)
	return sh (
		string.format    (
			info_v.curl.." | "..info_v.jq,
			package,
			"\027[1;34m",
			"\027[1;0m",
			"\027[1;34m",
			"\027[1;0m",
			"\027[1;34m",
			"\027[1;0m",
			"\027[1;34m",
			"\027[1;0m",
			"\027[1;34m",
			"\027[1;0m",
			"\027[1;34m",
			"\027[1;0m",
			"\027[1;34m",
			"\027[1;0m",
			"\027[1;36m",
			"\027[1;0m"
		)
	)
end

if (arg[1]=="search") then
	if (arg[2]==nil) then
		io.write("Search for ")
		r=search(io.read())
	else
		r=search(arg[2])
	end
elseif (arg[1]=="info") then
	if (arg[2]==nil) then
		io.write("Get info for ")
		r=info(io.read())
	else
		r=info(arg[2])
	end
else

end

print(r or "No operation specified!")
