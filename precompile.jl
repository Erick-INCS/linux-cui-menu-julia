#!/usr/bin/env julia

include(join(split(abspath(PROGRAM_FILE), "/")[1:end-1], "/") * "/AImages.jl")

using .AImages

mutable struct app
    name :: String
    path :: String
    icon :: String
end
    
# Globals
appsPath = "/usr/share/applications"
files = readdir(appsPath)
apps = []

regexName = r"Name=(.*)"
regexIcon = r"Icon=(.*)"
regexDE = r"[Desktop Entry]"
regexND = r"NoDisplay=true"

function getApp(filename :: String)

    desktop = open(f->read(f, String), appsPath * "/" * filename, "r")

    nm = match(regexName, desktop)
    ico = match(regexIcon, desktop)
    nd = match(regexND, desktop)
    de = match(regexDE, desktop)

    if nm !== nothing && ico !== nothing && nd === nothing && de !== nothing
	return app(nm.captures[1], filename, ico.captures[1])
    end
end

function findImage(a::app)
    baseDir = "/usr/share/icons"
    fn = `find $baseDir -iname "$(a.icon)*"`
    qry = match(r".+(.png|.jpg|.gif){1}", read(fn, String))

    a.icon = qry !== nothing ? chomp(qry.match) : ""
    return a
end

function displayApp(a::app)
    global index
    
    if a.icon !== ""
	img = permutedims(asciiImage(a.icon))
	img = permutedims([
	    reshape(
		[' ' for c in 1:lOffset
			for r in 1:AImages.imgSize] 
		,
		lOffset,
		:
	    )
	    ;
	    img
	])
    printAsciiImg(img)
    end

    
    println()
    for i=1:round(Int, screenSz[2]/2) - round(Int, length(a.name)/2)
	print(' ')
    end
    println(a.name)
    println("[" , index , "/" , length(apps) , "]")
end

# Process apps
apps = map(getApp, files)
apps = filter(a->a!==nothing, apps)
apps = map(findImage, apps)

# apps = filter(a->a.icon!="", apps)

const nApps = length(apps)
index = 1
screenSz = displaysize(stdout)
lOffset = round(Int, screenSz[2]/2)-round(Int, AImages.imgWidth/2)

while index <= length(apps)
    global index
    global screenSz
    global lOffset

    displayApp(apps[index])
    index += 1

    screenSz = displaysize(stdout)
    lOffset = round(Int, screenSz[2]/2)-round(Int, AImages.imgWidth/2)
end
