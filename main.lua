
--hello there! :3

fileprefix = "[converted] " --what appears before a converted filename


--dependencies i use for like every project i make
file = love.filesystem
sourcedir = love.filesystem.getSource()
sourcebasedir = love.filesystem.getSourceBaseDirectory()
render = love.graphics
width, height = love.graphics.getDimensions()
halfwidth = width/2
halfheight = height/2

Check = function(a, iftrue, iffalse) if a then return iftrue else return iffalse end end
Color = function(r,g,b,a) return {r/255, g/255, b/255, Check(a, a, 255) / 255} end
function clamp(val,min,max) 
    return math.max(math.min(val,max),min) 
end
math.clamp = clamp
dgetmeta = debug.getmetatable
function table.copy( tbl, lookup_table )
	if tbl == nil then return nil end
	local meta = dgetmeta( tbl )
	local copy = {}
	setmetatable( copy, meta )
	for i, v in pairs( tbl ) do
		if not (type(v) == "table") then
			copy[ i ] = v
		else
			lookup_table = lookup_table or {}
			lookup_table[ tbl ] = copy
			if ( lookup_table[ v ] ) then
				copy[ i ] = lookup_table[ v ] -- we already copied this table. reuse the copy.
			else
				copy[ i ] = table.copy( v, lookup_table ) -- not yet copied. copy it.
			end
		end
	end
	return copy
end


--worthy of note: order of elements in YAML file DOES NOT MATTER TO VVVF SIM (or to the standard as a whole, it seems)! so that's a plus :D
--for actual conversions: since i dont know how love2d behaves when the entire program is bundled in an .exe, i'll hardcode these and just update it later
available_converters = {
    [1] = "to v1.10.0.x",
}
converter_selected = 1
love.window.setTitle("YAML converter v1.9.x.x -> v1.10.0.x")


function extractFilename(str)
    local rev = str:reverse()
    local filename_start = string.find(rev, "\\")
    rev = string.sub(rev, 1, filename_start - 1)
    rev = rev:reverse()
    return rev
end
function love.filedropped(droppedfile)
    loaded_files = true
    local filepath = droppedfile:getFilename()
	local ext = filepath:match("%.%w+$")
    local filename = extractFilename(filepath)

    LogString("Opening \""..filename.."\"..", logcolor)
    droppedfile:open("r")
    local raw_yaml_data = droppedfile:read()
    droppedfile:close()

    if not raw_yaml_data then 
        LogString("Error loading file!", errorcolor)
        return
    end

    LogString("Converting..", logcolor)
    local converter = available_converters[converter_selected]
    converter, err = loadstring(file.read("converters/"..converter..".lua"))
    if err then 
        LogString("Error while loading converter! "..err, errorcolor)
        return
    end
    local new_filedata = converter(raw_yaml_data)

    --resolve new pathname
    local yaml_path = string.sub(filepath, 1, #filepath - #filename) --strip path to original file
    yaml_path = yaml_path .. fileprefix ..filename

    --writing to new file
    local writing_file,err = file.openNativeFile(yaml_path,"w")
    if err then LogString("Error creating file \""..yaml_path.."\"! "..tostring(err), errorcolor) return end
    writing_file:write(new_filedata)
    writing_file:close()
    LogString("Successful! written to \""..fileprefix ..filename.."\"!", successcolor)
end

--text colors
logcolor = Color(200,200,255)
successcolor = Color(100,220,100)
errorcolor = Color(255,20,20)
Black = Color(0,0,0)
White = Color(255,255,255)

--user interface stuff
LogScrollBarSize = 800
mouseinitialclick = {}
LogScroll = 0
LogScrollInit = 0
lastclicked = false
one = {1}
mpos = {}

Limit=1200 --how much to store inside of the log before deleting entries
logitems = {}
logitemscolors = {}
OffX = 20 --the offset of the log
OffY = 10
pages = 1
function LogString(str,color) --takes string and color, and prints it to the log
    ScreenUpdated=true
    local len=#logitems  
    local olditems=table.copy(logitems) 
    local oldlogitemscolors = table.copy(logitemscolors)

    for i=1,len do
        local item=olditems[i]
        logitems[i+1]=item
        logitemscolors[i+1] = oldlogitemscolors[i]
    end
    oldlogitemscolors = nil
    local len=#logitems
    local olditems=table.copy(logitems) 
    if len>Limit then
        local item=olditems[Limit+1]
        logitems[Limit+1]=nil
        logitemscolors[Limit+1]=nil
    end
    
    logitems[1]=str
    local color=Check(color,color,White)
    --[[for i=1,Limit do
        if not logitemscolors[i] then 
            logitemscolors[i] = color
            break
        end
    end]]
    logitemscolors[1] = color


    pages = math.floor((len * 32) / height) + 1
    LogScrollBarSize = height/pages
end

function ClearLog() 
    logitems = {}
    logitemscolors = {}
end


function love.resize(w, h)
    width = w
    height = h
    halfwidth = width/2
    halfheight = height/2
    pages = math.floor(((#logitems) * 32) / height) + 1
    LogScrollBarSize = height/pages

end



loaded_files = false

function love.draw()
    local mx,my = love.mouse.getPosition()
	local mleftclick = love.mouse.isDown(one)
	--local mrightclick = love.mouse.isDown(two)
	mpos[1] = mx
	mpos[2] = my

    --logscrollmins[2] = LogScroll
    --logscrollmaxes[2] = LogScroll + LogScrollBarSize
    if not loaded_files then 
        render.setColor(logcolor)
        local size = 100
        render.rectangle("fill", 30, halfheight - size / 2, width - 60, size)
        render.setColor(Black)
        text = "Drag and drop YAML file(s) to be converted to v1.10.0.x\n(the files will be saved to the same location as the YAML files, but with a \""..fileprefix.."\" at the start!)"
        render.printf(text, -100 * (width / 1000), halfheight - 20, width, "center", 0, 1.2, 1.2)
        return
    end
    render.setColor(White)
    render.rectangle("fill",width - 20,LogScroll,20,LogScrollBarSize)
    local div = 2
    for i=1, div do
        render.setColor(Color(120 - i * (120 / div),120 - i * (120 / div),255 - i * (180 / div)))
        render.rectangle("line",width - 20 - i * 2,LogScroll - i * 2,20 + i * 4,LogScrollBarSize + i * 4) --veri simple blurred purple outline to go along with scroll bar
    end
    if (lastclicked ~= "scrollbar") and mleftclick then --first click
        lastclicked = "scrollbar"
        mouseinitialclick[1] = mx
        mouseinitialclick[2] = my
        LogScrollInit = LogScroll
    elseif (lastclicked == "scrollbar") and mleftclick then --on hold 
        LogScroll = math.clamp(LogScrollInit + (my - mouseinitialclick[2]),0,height - LogScrollBarSize)
    elseif not mleftclick then  --let go
        lastclicked = false
    end

    local logcount = #logitems
    for i=0, logcount - 1 do 
        local color=logitemscolors[logcount - i]
        --print(i,color,logitems[i])
        render.setColor(color or Color(255,0,255))--,(color[4] or 255) - 170*Check(i>16,1,0))) 
        render.printf(logitems[logcount - i],OffX,i*32+OffY - LogScroll * pages,40000)
        --print(logitems[i])
    end
    --[[
    fpstime = systime() - (fpstime or 0)
    render.setColor(White)
    render.print("FPS: "..floor((10/fpstime))/10,10,10)
    fpstime = systime()]]

end