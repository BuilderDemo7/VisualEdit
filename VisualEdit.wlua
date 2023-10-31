local ui = require "ui"

local LabeledEntry = Object(ui.Entry)

function LabeledEntry:constructor(parent, text, x, y, width, height)
	self.label = ui.Label(parent, text, x, y)
	ui.Entry.constructor(self, parent, "", self.label.x + self.label.width + 6, self.label.y - 2, width or 120, height)
end

function table.equaltoany(t,val)
   for i,idx in pairs(t) do
      if val==idx then return true,i end
   end
   return false
end

local elementSizeBytes = 48
local elementSizeBytesDPL = 112 -- bigger, isn't it?
local supportedVersion = {37049,37053,61862}
local WiiVerMagic = 18000
local typeNames = {
  [1] = "Drawable",
  [2] = "Reserved (on car)",
  [137] = "Damage Bar",
  [153] = "Felony Bar",
  [145] = "Health Bar"
}
local elementFormat = "BBBBI2I2ffffffffff"
-- those f*cking integers I have no idea what it is!
-- OLD FORMAT unk1,unk2,unkm,unk3,unk4,unk5,unk6,unk7, type,unk8,unk9,unk10, input, unk11, unk12,unk13, r,g,b,a, x,y, w,h, sx,sy, id
-- OLD FORMAT 2 (it sucks) unk1,unk2,unk3,unk4, unk5,unk6, w2,h2, r,g,b,a, x,y, w,h, sx,sy, isx,isy, w3,h3, id,flags, unk7,unk8,unk9,unk10
-- r,g,b,a,x,y,w,h,input,unk1,sx,sy,unk2,unk3,id,flags,unk4,unk5,unk6,unk7,unk8,unk9,unk10,unk11,unk12,unk13,unk14,unk15
local elementFormatDPL = "fffffffffi4ffffi4i4i4i4i4i4i4i4i4i4i4i4i4i4" --"i4Bi4i4i4i4i4i4i4BBBBi2i2I4I4ffffffffffI8" -- OLD FORMAT
function binaryHUDFile(buffer,ver)
   if #buffer == 0 then 
      return "Fatal Error:\n== Out of memory ==\n\tBuffer size is equal to 0\tassuming no file"
   end 
   if #buffer<0x40 then
     return "Fatal Error:\n== Out of memory ==\n\tThe buffer size cannot be smaller than 64 bytes"
   end
   local count = string.unpack("I4",string.sub(buffer,3,6))
   local align = string.unpack("I8",string.sub(buffer,7,16))
   --print(string.byte(string.sub(buffer,7,16)))
   local HUD = {
      Version = ver, --string.unpack("I2",buffer),
	  Alignment = align,
	  Count = count,
    UnkBuffer = "",
    Magic = string.unpack("i4",string.sub(buffer,15,15+4)),
    Width = string.unpack("f",string.sub(buffer,15+4,64)), --1280,
    Height = string.unpack("f",string.sub(buffer,15+8,64)), --720,
	  Elements = {}
   } 
   print(string.format("Align: %d, Count: %d, Version: %d, Magic: %d",align,count,HUD.Version,HUD.Magic))
   local dpl = HUD.Version == 37053 or HUD.Version == 61862
   --local off = align
   --[[
   if dpl then 
       count = count-2
       HUD.UnkBuffer = string.sub(buffer,63,(64*3)-2)
   end
   ]]
   for eid=1,count do
      local s = elementSizeBytes
      -- is driver parallel lines
      if dpl then s = elementSizeBytesDPL end
      local off = align+(s*(eid-1))-1
      local omnwr = off>#buffer
      local oms = off+s-1>#buffer
      if omnwr or oms then local at = oms and off+s+1 or off return "Error:\n== Out of memory ==\n\tMissed "..s.." bytes at 0x"..string.format("%X",at) end
      local elemtable = {}
      --print("Processing "..eid.." element at "..tostring(off+1).." (inspect it in hex editor)") 
      local unk1,unk2,unk3,unk4,unk5,unk6,unk7,unk8,type,unk9,unk10,unk11,input,unk12,r,g,b,a,x,y,w,h,sx,sy,id
      -- Driv3r
      if HUD.Version == 37049 or HUD.Version == 61862 then
        --print("DRIVER THRIIIIE")
	     type,unk1,unk2,unk3,input,id,x,y,w,h,sx,sy,r,g,b,a = string.unpack(elementFormat,string.sub(buffer,off,off+elementSizeBytes+64))
	  -- main
    elemtable.Type = type 
	  elemtable.Align = unk1
	  elemtable.Unk2 = unk2
	  elemtable.Unk3 = unk3
    -- reserved
    elemtable.Unk4 = 0
    elemtable.Unk5 = 0
    elemtable.Unk6 = 0
    elemtable.Unk7 = 0
    elemtable.Unk8 = 0
    elemtable.Unk9 = 0
    elemtable.Unk10 = 0
    elemtable.Unk11 = 0
    elemtable.Unk12 = 0
    elemtable.Unk13 = 0
    elemtable.Unk14 = 0
    elemtable.Unk15 = 0
    -- drawing
	  elemtable.Input = input
    elemtable.ID = id
	  elemtable.X = x
	  elemtable.Y = y
	  elemtable.Width = w
	  elemtable.Height = h
	  elemtable.SizeX = sx
	  elemtable.SizeY = sy
	  elemtable.R,elemtable.G,elemtable.B,elemtable.A = r,g,b,a
    elemtable.Flags = 0
    --off = off+(elementSizeBytes*(eid-1))
	  --HUD.Elements[#HUD.Elements+1] = elemtable
    -- Driver: Parallel Lines
  elseif HUD.Version == 37053 or HUD.Version == 61862 then
    --print("DRIVER POROLOLELLAINES")
    local fmt = elementFormatDPL
    if HUD.Magic>=WiiVerMagic then fmt = ">"..fmt else fmt = elementFormatDPL end -- checks if it's Wii so we can make the order big-endian
	    r,g,b,a,x,y,w,h,input,unk1,sx,sy,unk2,unk3,id,flags,unk4,unk5,unk6,unk7,unk8,unk9,unk10,unk11,unk12,unk13,unk14,unk15 = string.unpack(fmt,string.sub(buffer,off,off+elementSizeBytesDPL+64))
	  -- main
    elemtable.Type = 0 
	  elemtable.Align = 0
    elemtable.Unk1 = unk1
	  elemtable.Unk2 = unk2
	  elemtable.Unk3 = unk3
    -- reserved
    elemtable.Unk4 = unk4
    elemtable.Unk5 = unk5
    elemtable.Unk6 = unk6
    elemtable.Unk7 = unk7
    elemtable.Unk8 = unk8
    elemtable.Unk9 = unk9
    elemtable.Unk10 = unk10
    elemtable.Unk11 = unk11
    elemtable.Unk12 = unk12
    elemtable.Unk13 = unk13
    elemtable.Unk14 = unk14
    elemtable.Unk15 = unk15
    -- magic value?
    --elemtable.UnkM = unkm
    -- drawing
	  elemtable.Input = input
    elemtable.ID = id
	  elemtable.X = x
	  elemtable.Y = y
	  elemtable.Width = w
	  elemtable.Height = h
	  elemtable.SizeX = sx
	  elemtable.SizeY = sy
	  elemtable.R,elemtable.G,elemtable.B,elemtable.A = r,g,b,a
    elemtable.Flags = flags
    --off = off+(elementSizeBytesDPL*(eid-1))
  else
    return "Cannot determine elements for version "..HUD.Version 
  end
    HUD.Elements[#HUD.Elements+1] = elemtable
    if not (dpl==true) then
       --print("INFO",type,unk1,unk2,unk3,input,id,"POS",x,y,"SIZE PX",w,h,"SIZE R",sx,sy,"COLOR",r,g,b,a)
    else 
       --print("UNK",unk1,unk2,unkm,unk3,unk4,unk5,unk6,unk7, "INFO", type,id,unk8,unk9,unk10, input, unk11, unk12,unk13, "COLOR", r,g,b,a, "POS", x,y, "SIZE PX", w,h, "SIZE R", sx,sy, "ID", id)
    end
   end
   return HUD
end

local binaryMagic = 61862
local binaryMagic2 = 1648
function newBinaryHUDFile(HUD)
   local buffer = string.pack("I2",HUD.Version)..string.pack("I2",binaryMagic)..string.pack("I4",#HUD.Elements)..string.pack("I8",HUD.Alignment)..string.pack("i4",HUD.Magic)..string.pack("ff",HUD.Width,HUD.Height)..string.rep(string.char(0), ( 46-(4*2) )-2 )..HUD.UnkBuffer
   for elemID=1,#HUD.Elements do
      local elemtable = HUD.Elements[elemID]
      local bin = ""
      if HUD.Version == 37049 then
        bin = string.pack(elementFormat,elemtable.Type, elemtable.Align,elemtable.Unk2,elemtable.Unk3,elemtable.Input,elemtable.ID,elemtable.X,elemtable.Y,elemtable.Width,elemtable.Height,elemtable.SizeX,elemtable.SizeY,elemtable.R,elemtable.G,elemtable.B,elemtable.A)
       elseif HUD.Version == 37053 then
           local fmt = elementFormatDPL
           if HUD.Magic>=WiiVerMagic then fmt = ">"..fmt end -- checks if it's Wii so we can make the order big-endian          
           local r,g,b,a,x,y,w,h,input,unk1,sx,sy,unk2,unk3,id,flags,unk4,unk5,unk6,unk7,unk8,unk9,unk10,unk11,unk12,unk13,unk14,unk15 = elemtable.R, elemtable.G,elemtable.B,elemtable.A,elemtable.X,elemtable.Y,elemtable.Width,elemtable.Height,elemtable.Input,elemtable.Unk1,elemtable.SizeX,elemtable.SizeY,elemtable.Unk2,elemtable.Unk3,elemtable.ID,elemtable.Flags,elemtable.Unk4,elemtable.Unk5,elemtable.Unk6,elemtable.Unk7,elemtable.Unk8,elemtable.Unk9,elemtable.Unk10,elemtable.Unk11,elemtable.Unk12,elemtable.Unk13,elemtable.Unk14,elemtable.Unk15
           print(sx,sy,w,h)
           print(id)
          bin = string.pack(fmt,r,g,b,a,x,y,w,h,input,unk1,sx,sy,unk2,unk3,id,flags,unk4 or 0,unk5 or 0,unk6 or 0,unk7 or 0,unk8 or 0,unk9 or 0,unk10 or 0,unk11 or 0,unk12 or 0,unk13 or 0,unk14 or 0,unk15 or 0,0,0,0,0)
       else
          ui.error("Unknown version "..HUD.Version)
          return nil
       end
       buffer = buffer..bin
   end
   return buffer
end

function noBinaryHUDFile()
   return {Version=0,Alignment=40,UnkBuffer = "",Magic=0,Width=0,Height=0,Elements = {}}
end

require "canvas"

local supportedFormats = {
   "Driv3r/Driver: Parallel Lines binary HUD files (*.bin)|*.bin"
}
local undoElements = {}
--local redoElements = {}
local lastfile
local currentbinhud = noBinaryHUDFile()
local selected = {}
local copied = {}
local filechanged = false
local xOff,yOff = 0,0 -- draw offsets 
local ent_yoff = 30
local btn_sx = 50
-- list of elements window
local listwin = ui.Window("List of elements","fixed",256,256)
local elemListUI = ui.List(listwin,{},0,0,0,0)
elemListUI.align = "all"
function updateElementList()
   elemListUI:clear()
   
   for i=1,#currentbinhud.Elements do
      local elemType = "Element"
      elemListUI:add(string.format("[%d] %s",i,elemType))
   end
   if not (#selected == 0) then
      elemListUI.selected = elemListUI.items[selected[1]]
   end
end
function elemListUI:onDoubleClick(item)
   selected = {item.index}
end
listwin:center()
-- Set safe area window
local safewin = ui.Window("Aspect Editor","fixed",512,180)
local lab_safeinfo = ui.Label(safewin,"You can move elements away from the corners with this, you CAN'T undo this action once.",20,10)
-- sf
local ent_sfax = LabeledEntry(safewin,"Safe Area Horizontally ",20,20+ent_yoff,48,18)
ent_sfax.text = "1.0"
local ent_sfay = LabeledEntry(safewin,"Safe Area Vertically      ",20,40+ent_yoff,48,18)
ent_sfay.text = "1.0"
-- move
local ent_max = LabeledEntry(safewin,"Move Horizontally ",250,20+ent_yoff,48,18)
ent_max.text = "0"
local ent_may = LabeledEntry(safewin,"Move Vertically      ",250,40+ent_yoff,48,18)
ent_may.text = "0"
-- resize
local ent_rax = LabeledEntry(safewin,"Resize Horizontally ",250,60+ent_yoff,48,18)
ent_rax.text = "0"
local ent_ray = LabeledEntry(safewin,"Resize Vertically      ",250,80+ent_yoff,48,18)
ent_ray.text = "0"
-- resolution
local ent_reax = LabeledEntry(safewin,"Resolution X          ",250,100+ent_yoff,48,18)
ent_reax.text = "0"
local ent_reay = LabeledEntry(safewin,"Resolution Y          ",250,120+ent_yoff,48,18)
ent_reay.text = "0"
local btn_set2 = ui.Button(safewin,"Set",0+btn_sx,60+ent_yoff,btn_sx,20)
local btn_set3 = ui.Button(safewin,"Move",0+btn_sx*2,60+ent_yoff,btn_sx,20)
local btn_set4 = ui.Button(safewin,"Resize",0+btn_sx*3,60+ent_yoff,btn_sx,20)
local cbox_csize = ui.Checkbox(safewin,"Stretch",0+btn_sx,90+ent_yoff,btn_sx,30,55)
cbox_csize.width = #cbox_csize.text*10
safewin:center()
safewin:hide()
-- Edit Window
local editwin = ui.Window("Properities","fixed",512,280) -- x,y 512,280
editwin:center()
-- Edit Window Stuff
local lab_id = LabeledEntry(editwin,"Selected",20,10)
local lab_swap = LabeledEntry(editwin,"Swap index with",250,10)
lab_swap.text = "0"
-- general
local ent_type = LabeledEntry(editwin,"Type ",20,20+ent_yoff,48,18)
local ent_unk1 = LabeledEntry(editwin,"Align ",20,40+ent_yoff,48,18)
local ent_unk2 = LabeledEntry(editwin,"Unk2 ",20,60+ent_yoff,48,18)
local ent_unk3 = LabeledEntry(editwin,"Unk3 ",20,80+ent_yoff,48,18)
local ent_unk4 = LabeledEntry(editwin,"Unk4 ",20,100+ent_yoff,48,18)
local ent_unk5 = LabeledEntry(editwin,"Unk5 ",20,120+ent_yoff,48,18)
local ent_unk6 = LabeledEntry(editwin,"Unk6 ",48*3,120+ent_yoff,48,18)
local ent_unk7 = LabeledEntry(editwin,"Unk7 ",48*3,140+ent_yoff,48,18)
local ent_unk8 = LabeledEntry(editwin,"Unk8 ",48*3,160+ent_yoff,48,18)
local ent_unk9 = LabeledEntry(editwin,"Unk9 ",48*3,180+ent_yoff,48,18)
local ent_unk10 = LabeledEntry(editwin,"Unk10 ",48*5,120+ent_yoff,48,18)
local ent_unk11 = LabeledEntry(editwin,"Unk11 ",48*5,140+ent_yoff,48,18)
local ent_unk12 = LabeledEntry(editwin,"Group ",48*5,160+ent_yoff,48,18)
local ent_unk13 = LabeledEntry(editwin,"Func  ",48*5,180+ent_yoff,48,18)
local ent_unk14 = LabeledEntry(editwin,"Unk14 ",48*7,120+ent_yoff,48,18)
local ent_unk15 = LabeledEntry(editwin,"Unk15 ",48*7,140+ent_yoff,48,18)
local ent_inp = LabeledEntry(editwin,"Input ",20,160+ent_yoff,48,18)
local ent_id = LabeledEntry(editwin,"ID ",20,180+ent_yoff,48,18)
local ent_flags = LabeledEntry(editwin,"Flags ",20,200+ent_yoff,48,18)
-- draw
local ent_x = LabeledEntry(editwin,"X",48*3,20+ent_yoff,48,18)
local ent_y = LabeledEntry(editwin,"Y",48*5,20+ent_yoff,48,18)
local ent_w = LabeledEntry(editwin,"Width ",48*3,40+ent_yoff,48,18)
local ent_h = LabeledEntry(editwin,"Height",48*5,40+ent_yoff,48,18)
local ent_sx = LabeledEntry(editwin,"Size X",48*3,60+ent_yoff,48,18)
local ent_sy = LabeledEntry(editwin,"Size Y",48*5,60+ent_yoff,48,18)
local ent_qx = LabeledEntry(editwin,"Quad X",48*3,80+ent_yoff,48,18)
local ent_qy = LabeledEntry(editwin,"Quad Y",48*5,80+ent_yoff,48,18)
-- color
local ent_r = LabeledEntry(editwin,"R ",48*7,20+ent_yoff,48,18)
local ent_g = LabeledEntry(editwin,"G ",48*7,40+ent_yoff,48,18)
local ent_b = LabeledEntry(editwin,"B ",48*7,60+ent_yoff,48,18)
local ent_a = LabeledEntry(editwin,"A ",48*7,80+ent_yoff,48,18)
-- edit
local btn_xoff = 300
local btn_get = ui.Button(editwin,"Get",btn_xoff,210+ent_yoff,btn_sx,40)
local btn_set = ui.Button(editwin,"Set",btn_xoff+btn_sx,210+ent_yoff,btn_sx,40)
local btn_delete = ui.Button(editwin,"Remove",btn_xoff+btn_sx*2,210+ent_yoff,btn_sx,40)
local btn_select = ui.Button(editwin,"Select",btn_xoff+btn_sx*3,210+ent_yoff,btn_sx,40)
-- Main Window
local programtitle = "Visual Edit"
local win = ui.Window("Visual Edit",512,512)
win.menu = ui.Menu()
-- Edit Window Stuff
local FileMenu = ui.Menu()
win.menu:add("&File").submenu = FileMenu
local openButton = FileMenu:add("&Open")
FileMenu:add("")
local closeButton = FileMenu:add("&Close")
closeButton.enabled = false -- by default
FileMenu:add("")
local saveButton = FileMenu:add("&Save")
local saveAsButton = FileMenu:add("&Save As")
saveButton.enabled = false -- by default
saveAsButton.enabled = false -- by default
local EditMenu = ui.Menu()
win.menu:add("&Edit").submenu = EditMenu
--EditMenu:add("") -- seperator
local listButton = EditMenu:add("&List of elements")
function listButton:onClick()
   win:showmodal(listwin)
   updateElementList()
end
local safeAreaButton = EditMenu:add("&Aspect Editor\tT")
EditMenu:add("") -- seperator
local editButton = EditMenu:add("&Properities\tCtrl+E")
local newElemButton = EditMenu:add("&New Element\tCtrl+N")
EditMenu:add("") -- seperator
local copyButton = EditMenu:add("&Copy\tCtrl+C")
local pasteButton = EditMenu:add("&Paste\tCtrl+V")
pasteButton.enabled = false
local duplicateButton = EditMenu:add("&Duplicate\tCtrl+D")
local deleteButton = EditMenu:add("&Delete\tDelete")
EditMenu:add("") -- seperator
local multiSel = EditMenu:add("&Multi-select")
local boxSel = EditMenu:add("&Box-select")
function multiSel:onClick() 
   multiSel.checked = not multiSel.checked 
end
function boxSel:onClick() 
   boxSel.checked = not boxSel.checked 
end
local selectAll = EditMenu:add("&Select All\tCtrl+A")
function selectAll:onClick()
   if #selected == #currentbinhud.Elements then selected = {} return end
   for i=1,#currentbinhud.Elements do
      table.insert(selected,i,i)
   end
end
win:shortcut("a",selectAll.onClick,true)
local selectNone = EditMenu:add("&Unselect All")
function selectNone:onClick()
   selected = {}
end
EditMenu:add("") -- seperator
local undoButton = EditMenu:add("&Undo\tCtrl+Z")
undoButton.enabled = false
--local redoButton = EditMenu:add("&Redo\tCtrl+Y")
local GridMenu = ui.Menu()
win.menu:add("&View").submenu = GridMenu
local grid = 16
local gRes = GridMenu:add("&Reset")
local g8 = GridMenu:add("&Snap: 8 (1/2 fps)")
local g16 = GridMenu:add("&Snap: 16")
local g32 = GridMenu:add("&Snap: 32")
local g64 = GridMenu:add("&Snap: 64")
local g128 = GridMenu:add("&Snap: 128")
local g256 = GridMenu:add("&Snap: 256")
local g512 = GridMenu:add("&Snap: 512")
local gNone = GridMenu:add("&Snap: None")
function gRes:onClick() xOff = 0 yOff = 0 end
function g8:onClick() grid = 8 end
function g16:onClick() grid = 16 end
function g32:onClick() grid = 32 end
function g64:onClick() grid = 64 end
function g128:onClick() grid = 128 end
function g256:onClick() grid = 256 end
function g512:onClick() grid = 512 end
function gNone:onClick() grid = "none" end
function showEditWindow()
   btn_get:onClick()  -- auto
   win:showmodal(editwin)
end
win:shortcut("e", showEditWindow, true)
function showSafeAreaEditWindow()
   win:showmodal(safewin)  
end
win:shortcut("t", showEditWindow)
safeAreaButton.onClick = showSafeAreaEditWindow
-- help
local HelpMenu = ui.Menu()
win.menu:add("&Help").submenu = HelpMenu
local aboutButton = HelpMenu:add("&About\tF1")
local helpButton = HelpMenu:add("&How to Use")
local build = "Version 0.1BA Oct. 31" --"Build October 27 9485"
function aboutButton:onClick()
   ui.info("Made with LuaRT Lua Framework v1.5.2\nAuthor: BuilderDemo7\nBeta Testers: NismoRacer00 & Sunrise_424\n\t"..build,"About")
end
win:shortcut("f1", aboutButton.onClick)
function helpButton:onClick()
   ui.msg("[1] SELECTING FEATURES\n\nIn Edit >> Properities (Ctrl+E) you can select elements by the 'Selected' box if you type the ID of the element or select multiple, for example: if you type in '10>20' it will select from 10 to 20 or if you type in '10,11,12,13,18,22' it will select multiple elements as you ordered.\t\n\n[2] BASIC\n\nGo to File then Open and open a HUD file, after it you can do various things with it and then save your work in Save.\t\n\n[3] MOUSE\t\n\nTo move an element with your mouse hold your mouse button until the cursor turns into green while holding release into somewhere else.\n\n[4] KEYS\t\n\nWASD - Move around\nShift - Reset view\nArrow keys - Move selected element","How to Use")
end
function fileChangedTitle()
   if filechanged and not (string.sub(win.title,#win.title,#win.title)== "*") then
      win.title = win.title.."*"
   end
end
function setFileAsChanged()
   filechanged = true
   saveButton.enabled = true
   saveAsButton.enabled = true
   fileChangedTitle()  
end
function string.hex(d)
   return string.format("0x%X",d)
end
-- edit buttons functions
-- get
function setAllUIPropsTo(s)
       ent_type.text = s
       ent_unk1.text = s
       ent_unk2.text = s
       ent_unk3.text = s
       -- is driver parallel lines
       if currentbinhud.Version == 37053 then
       ent_unk4.text = s
       ent_unk5.text = s
       ent_unk6.text = s
       ent_unk7.text = s
       ent_unk8.text = s
       ent_unk9.text = s
       ent_unk10.text = s
       ent_unk11.text = s
       ent_unk12.text = s
       ent_unk13.text = s
       ent_unk14.text = s
       ent_unk15.text = s
       -- flags
       ent_flags.text = s
       ent_qx.text = s
       end
       ent_inp.text = s
       ent_id.text = s
       ent_x.text = s
       ent_y.text = s
       ent_w.text = s
       ent_h.text = s
       ent_sx.text = s
       ent_sy.text = s
       ent_r.text = s
       ent_g.text = s
       ent_b.text = s
       ent_a.text = s
end
function get()
    if not (#selected == 0) then
       local elem = currentbinhud.Elements[selected[1]]
       if not (currentbinhud.Version == 37053) then
          ent_type.text = elem.Type
       else
          ent_type.text = "(D3-only)"
       end
       ent_unk1.text = elem.Align
       ent_unk2.text = elem.Unk2
       ent_unk3.text = elem.Unk3
       -- is driver parallel lines
       if currentbinhud.Version == 37053 then
         -- quad
       ent_qx.text = elem.Input
       ent_unk4.text = elem.Unk4
       ent_unk5.text = elem.Unk5      
       ent_unk6.text = elem.Unk6
       ent_unk7.text = elem.Unk7
       ent_unk8.text = elem.Unk8
       ent_unk9.text = elem.Unk9
       ent_unk10.text = string.hex(elem.Unk10)
       ent_unk11.text = string.hex(elem.Unk11)
       ent_unk12.text = string.hex(elem.Unk12)
       ent_unk13.text = string.hex(elem.Unk13)
       ent_unk14.text = string.hex(elem.Unk14)
       ent_unk15.text = string.hex(elem.Unk15)
       -- flags
       ent_flags.text = elem.Flags
     end
       if not (currentbinhud.Version == 37053) then
          ent_inp.text = string.hex(elem.Input)
       else
          ent_inp.text = "(D3-only)"
       end
       ent_id.text = elem.ID
       ent_x.text = elem.X
       ent_y.text = elem.Y
       ent_w.text = elem.Width
       ent_h.text = elem.Height
       ent_sx.text = elem.SizeX
       ent_sy.text = elem.SizeY
       ent_r.text = elem.R
       ent_g.text = elem.G
       ent_b.text = elem.B
       ent_a.text = elem.A
       ent_type.enabled = true
       ent_unk1.enabled = true
       ent_unk2.enabled = true
       ent_unk3.enabled = true
       ent_inp.enabled = true
       ent_id.enabled = true
       ent_x.enabled = true
       ent_y.enabled = true
       ent_w.enabled = true
       ent_h.enabled = true
       ent_sx.enabled = true
       ent_sy.enabled = true
       ent_r.enabled = true
       ent_g.enabled = true
       ent_b.enabled = true
       ent_a.enabled = true       
       btn_delete.enabled = true
       -- is drover parallel lines lol
       if currentbinhud.Version == 37053 then
       ent_unk4.enabled = true
       ent_unk5.enabled = true
       ent_unk6.enabled = true
       ent_unk7.enabled = true
       ent_unk8.enabled = true
       ent_unk9.enabled = true
       ent_unk10.enabled = true
       ent_unk11.enabled = true
       ent_unk12.enabled = true
       ent_unk13.enabled = true
       ent_unk14.enabled = true
       ent_unk15.enabled = true
       -- flags
       ent_flags.enabled = true
       -- quad
       ent_qx.enabled = true  
       ent_inp.enabled = false
       ent_type.enabled = false
     else
       ent_unk4.enabled = false
       ent_unk5.enabled = false
       ent_unk6.enabled = false
       ent_unk7.enabled = false
       ent_unk8.enabled = false
       ent_unk9.enabled = false
       ent_unk10.enabled = false
       ent_unk11.enabled = false
       ent_unk12.enabled = false
       ent_unk13.enabled = false
       ent_unk14.enabled = false
       ent_unk15.enabled = false
       -- flags
       ent_flags.enabled = false
       ent_qx.enabled = false
       ent_inp.enabled = true
       ent_type.enabled = true
       end
       if #selected>1 then setAllUIPropsTo("...") end       
    else
       ent_type.enabled = false
       ent_unk1.enabled = false
       ent_unk2.enabled = false
       ent_unk3.enabled = false
       ent_unk4.enabled = false
       ent_unk5.enabled = false
       ent_unk6.enabled = false
       ent_unk7.enabled = false
       ent_unk8.enabled = false
       ent_unk9.enabled = false
       ent_unk10.enabled = false
       ent_unk11.enabled = false
       ent_unk12.enabled = false
       ent_unk13.enabled = false
       ent_unk14.enabled = false
       ent_unk15.enabled = false
       ent_inp.enabled = false
       ent_id.enabled = false
       ent_x.enabled = false
       ent_y.enabled = false
       ent_w.enabled = false
       ent_h.enabled = false
       ent_sx.enabled = false
       ent_sy.enabled = false
       ent_r.enabled = false
       ent_g.enabled = false
       ent_b.enabled = false
       ent_a.enabled = false
       btn_delete.enabled = false
    end  
end
function btn_get:onClick()
    lab_id.text = selected[1] == nil and "0" or table.concat(selected,",") --selected[1] == nil and "0" or selected[1]
    get()
end
function split(s, delimiter)
	result = {}
  if s == nil then return end
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
	return result
end
function btn_select:onClick()
    --local n = tonumber(lab_id.text)
    local t = split(lab_id.text,",")
    local tillt = string.find(lab_id.text,">")
    if not (t==nil) and not (tonumber(t[1])==0) --[[and n<#currentbinhud.Elements]] then
       selected = {}
       if tillt then
          print(string.sub(lab_id.text,1,tillt))
          local n1,n2 = tonumber(string.sub(lab_id.text,1,tillt-1)),tonumber(string.sub(lab_id.text,tillt+1,#lab_id.text))
          if n2>#currentbinhud.Elements then ui.error("The second number cannot be bigger than "..#currentbinhud.Elements,"Error") return end
          for till=n1,n2,n1>n2 and -1 or 1 do
             table.insert(selected,#selected+1,till)
          end
          t = {} -- cancel the other format
       end
       for selID=1,#t do
          if not (tonumber(t[selID]) == nil or tonumber(t[selID]) == 0) then
            table.insert(selected,#selected+1,tonumber(t[selID]))
          end
       end
    else
       ui.error("Failed to select element(s) '"..lab_id.text.."'")
    end
end 
function addTableToUndoList(t,idx,act,propname,val)
   table.insert(undoElements,#undoElements+1,{t=t,idx=selected,act=act,propname=propname,val=val})
end
function btn_delete:onClick()
   if not(selected==0) and ui.confirm("Are you sure you want to remove this element? you can un-do your action in Edit menu","Remove?") == "yes" then
      --table.insert(undoElements,#undoElements+1,{t=currentbinhud.Elements[selected],idx=selected,act="delete",prop=0})
      for selID=1,#selected do
      addTableToUndoList(currentbinhud.Elements[selected[selID]],selected[selID],"delete")
      table.remove(currentbinhud.Elements,selected[selID])
    end
      undoButton.enabled = true
      selected = {}
      btn_get:onClick() 
   end
end
deleteButton.onClick = btn_delete.onClick
--win:shortcut("vk_delete", btn_delete.onClick)
-- set
--[[
local test1 = 5
local test2 = 2
test1,test2 = test2,test1
print(test1,test2)]]
function set()
    if not (#selected == 0) and (ent_type.enabled == true or ent_type.enabled == false and currentbinhud.Version == 37053) then
      for selID=1,#selected do
       local elem = currentbinhud.Elements[selected[selID]]
       elem.Type = tonumber(ent_type.text) == nil and elem.Type or tonumber(ent_type.text)
       elem.Align = tonumber(ent_unk1.text) == nil and elem.Align or tonumber(ent_unk1.text)
       elem.Unk2 = tonumber(ent_unk2.text) == nil and elem.Unk2 or tonumber(ent_unk2.text)
       elem.Unk3 = tonumber(ent_unk3.text) == nil and elem.Unk3 or tonumber(ent_unk3.text)
       if currentbinhud.Version == 37053 then
          elem.Unk4 = tonumber(ent_unk4.text) == nil and elem.Unk4 or tonumber(ent_unk4.text)
          elem.Unk5 = tonumber(ent_unk5.text) == nil and elem.Unk5 or tonumber(ent_unk5.text)
          elem.Unk6 = tonumber(ent_unk6.text) == nil and elem.Unk6 or tonumber(ent_unk6.text)
          elem.Unk7 = tonumber(ent_unk7.text) == nil and elem.Unk7 or tonumber(ent_unk7.text)
          elem.Unk8 = tonumber(ent_unk8.text) == nil and elem.Unk8 or tonumber(ent_unk8.text)
          elem.Unk9 = tonumber(ent_unk9.text) == nil and elem.Unk9 or tonumber(ent_unk9.text)
          elem.Unk10 = tonumber(ent_unk10.text) == nil and elem.Unk10 or tonumber(ent_unk10.text)
          elem.Unk11 = tonumber(ent_unk11.text) == nil and elem.Unk11 or tonumber(ent_unk11.text)
          elem.Unk12 = tonumber(ent_unk12.text) == nil and elem.Unk12 or tonumber(ent_unk12.text)
          elem.Unk13 = tonumber(ent_unk13.text) == nil and elem.Unk13 or tonumber(ent_unk13.text)
          elem.Unk14 = tonumber(ent_unk14.text) == nil and elem.Unk14 or tonumber(ent_unk14.text)
          elem.Unk15 = tonumber(ent_unk15.text) == nil and elem.Unk15 or tonumber(ent_unk15.text)
          -- flags
          elem.Flags = tonumber(ent_flags.text) == nil and elem.Flags or tonumber(ent_flags.text)
          -- quad
          elem.Input = tonumber(ent_qx.text) == nil and elem.Input or tonumber(ent_qx.text)
       end
       if not (currentbinhud.Version == 37053) then
          elem.Input = tonumber(ent_inp.text) == nil and elem.Input or tonumber(ent_inp.text)
       end
       elem.ID = tonumber(ent_id.text) == nil and elem.ID or tonumber(ent_id.text)
       --if not (tonumber(ent_x.text) == nil) and not (ent_x.text == tostring(elem.X)) then addTableToUndoList(elem,selected[selID],"setprop","X",elem.X) end -- checks if it changed and add it to undo list
       elem.X = tonumber(ent_x.text) == nil and elem.X or tonumber(ent_x.text)
       --if not (tonumber(ent_y.text) == nil) and not (ent_y.text == tostring(elem.Y)) then addTableToUndoList(elem,selected[selID],"setprop","Y",elem.Y) end -- checks if it changed and add it to undo list
       elem.Y = tonumber(ent_y.text) == nil and elem.Y or tonumber(ent_y.text)
       --if not (tonumber(ent_w.text) == nil) and not (ent_w.text == tostring(elem.Width)) then addTableToUndoList(elem,selected[selID],"setprop","Width",elem.Width) end -- checks if it changed and add it to undo list
       elem.Width = tonumber(ent_w.text) == nil and elem.Width or tonumber(ent_w.text)
       --if not (tonumber(ent_h.text) == nil) and not (ent_h.text == tostring(elem.Height)) then addTableToUndoList(elem,selected[selID],"setprop","Height",elem.Height) end -- checks if it changed and add it to undo list
       elem.Height = tonumber(ent_h.text) == nil and elem.Height or tonumber(ent_h.text)
       --if not (tonumber(ent_sx.text) == nil) and not (ent_sx.text == tostring(elem.SizeX)) then addTableToUndoList(elem,selected[selID],"setprop","SizeX",elem.SizeX) end -- checks if it changed and add it to undo list
       elem.SizeX = tonumber(ent_sx.text) == nil and elem.SizeX or tonumber(ent_sx.text)
       --if not (tonumber(ent_sy.text) == nil) and not (ent_sy.text == tostring(elem.SizeY)) then addTableToUndoList(elem,selected[selID],"setprop","SizeY",elem.SizeY) end -- checks if it changed and add it to undo list
       elem.SizeY = tonumber(ent_sy.text) == nil and elem.SizeY or tonumber(ent_sy.text)
       elem.R = tonumber(ent_r.text) == nil and elem.R or tonumber(ent_r.text)
       elem.G = tonumber(ent_g.text) == nil and elem.G or tonumber(ent_g.text)
       elem.B = tonumber(ent_b.text) == nil and elem.B or tonumber(ent_b.text)
       elem.A = tonumber(ent_a.text) == nil and elem.A or tonumber(ent_a.text)
       setFileAsChanged()
       -- swap if needed or not
          if not (lab_swap.text == "0" or tonumber(lab_swap.text) == nil) then
             currentbinhud.Elements[selected[selID]],currentbinhud.Elements[tonumber(lab_swap.text)] = currentbinhud.Elements[tonumber(lab_swap.text)],currentbinhud.Elements[selected[selID]]
             lab_swap.text = "0"
          end
       end
    else
       ui.error("Failed to set values, Please verify and try again!")
    end  
end
function btn_set:onClick() 
    lab_id.text = selected[1]
    set()
end
function saveAsButton:onClick()
   if #currentbinhud.Elements == 0 then
      ui.info("No HUD to save!")
      return
   end
   local dialog = table.concat(supportedFormats,"|")
   local file = ui.savedialog("Save binary HUD file",nil,dialog)
   if file then
      if file.exists == true then if not (ui.confirm("This file already exists, overwrite? (NO backup files will be created!!)","Overwrite?") == "yes") then return end end 
      local f = io.open(file.fullpath,"wb")
      if not f then ui.error("File is read-only or is being used by an another process, please try again later!") return end
      if currentbinhud.Elements then
         local buff = newBinaryHUDFile(currentbinhud)
         if buff then
            f:write(buff)
            ui.info("Saved with success! - "..file.fullpath)
         else
            ui.error("An error has occurred, please verify everything and try again!")
         end
      end
      lastfile = file
      f:close()
   end
end
function saveButton:onClick()
   if lastfile then
      if not (ui.confirm("Are you sure you want to overwrite? NO BACKUP FIlES WILL BE CREATED!","Save?") == "yes") then return end 
      local f = io.open(lastfile.fullpath,"wb")
      if not f then ui.error("File is read-only or is being used by an another process, please try again later!") return end
      if currentbinhud.Elements then
         local buff = newBinaryHUDFile(currentbinhud)
         if buff then
            f:write(buff)
            ui.info("Saved with success! - "..lastfile.fullpath)
         else
            ui.error("An error has occurred, please verify everything and try again!")
         end
      end
      f:close()
   else
      ui.info("No file to save!")
   end
end
function undo()
   if not (#undoElements==0) then
      --for undoId=1,#undoElements do
         local act = undoElements[#undoElements].act
         if act == "delete" then
           table.insert(currentbinhud.Elements,undoElements[#undoElements].idx,undoElements[#undoElements].t)
         elseif act == "create" then
           table.remove(currentbinhud.Elements,undoElements[#undoElements].idx)
         elseif act == "move" then
           currentbinhud.Elements[undoElements[#undoElements].idx].X = undoElements[#undoElements].t.X
           currentbinhud.Elements[undoElements[#undoElements].idx].Y = undoElements[#undoElements].t.Y
           --table.remove(currentbinhud.Elements,undoElements[#undoElements].idx)    
           --table.insert(currentbinhud.Elements,undoElements[#undoElements].idx,undoElements[#undoElements].t)   
         elseif act == "setprop" and not (undoElements[#undoElements].propname == nil) then
           --print(string.format("idx = %d, propname = %s, val = %d",undoElements[#undoElements].idx,tostring(undoElements[#undoElements].propname),undoElements[#undoElements].val))
           local prop
           print(undoElements[#undoElements].idx)
           if undoElements[#undoElements].propname == "X" then prop = currentbinhud.Elements[undoElements[#undoElements].idx].X end
           if prop then prop = undoElements[#undoElements].val end
          else
            print("Unknown undo act "..act)
         end
         table.remove(undoElements,#undoElements)
         if #undoElements == 0 then undoButton.enabled = false end
      --end
   end
end
function undoButton:onClick()
   undo()
end
win:shortcut("z", undoButton.onClick, true)
function closeButton:onClick()
   if lastfile then
      local confirm = "yes"
      if filechanged == true then
         confirm = ui.confirm("You have unsaved changes, are you sure you want to close the file?","Close?")
      end
      if confirm == "yes" or filechanged == false then
         win.title = programtitle
         selected = {}
         currentbinhud = noBinaryHUDFile()
         undoElements = {}
         lastfile = nil
         closeButton.enabled = false
         saveButton.enabled = false
         saveAsButton.enabled = false
      end
   end
end

local hasClicked = false
local lastX,lastY = 0,0 -- last clicked pos
local Canvas = ui.Canvas(win)
--[[
local W,H = 640,640
Canvas.width = 640
Canvas.height = 640
]]
Canvas.bgcolor = 0x000000FF
Canvas.align = "all"
Canvas.sync = false
--Canvas.drawing = true
win:center()

function editButton:onClick()
   showEditWindow()
end

function Canvas:aspectRatio(x,y)
   return Canvas.width*x,Canvas.height*y
end

function Canvas:cross(x,y,size,color,width)
   self:line(x+size,y+size,x-size,y-size,color,width)
   self:line(x+size,y-size,x-size,y+size,color,width)
end

function projectElement(elem)
      if not (elem==nil) then
      local x,y = Canvas:aspectRatio(elem.X,elem.Y)
      x,y = x-xOff,y-yOff
      local sx,sy = elem.SizeX,elem.SizeY
      sx = sx<0.001 and 1 or sx
      sy = sy<0.001 and 1 or sy
      local w,h = elem.Width*(Canvas.width/Canvas.height)*sx,elem.Height*(Canvas.width/Canvas.height)*sy
      --w,h = w*elem.SizeX,h*elem.SizeY  
      return x,y,w,h
      end
end

function newElemButton:onClick()
   local newElem = {
     Type = 1,
     Align = 0,
     Unk2 = 0,
     Unk3 = 0,
     Unk4 = 0,
     Unk5 = 0,
     Unk6 = 0,
     Unk7 = 0,
     Unk8 = 0,
     Unk9 = 0,
     Unk10 = 0,
     Unk11 = 0,
     Unk12 = 0,
     Unk13 = 0,
     Unk14 = 0,
     Unk15 = 0,
     Input = 15,
     ID = 1,
     X = lastX/Canvas.width,
     Y = lastY/Canvas.height,
     Width = 128,
     Height = 128,
     SizeX = 1.0,
     SizeY = 1.0,
     R=1.0,G=1.0,B=1.0,A=1.0
   }
   table.insert(currentbinhud.Elements,#currentbinhud.Elements+1,newElem)
   selected = {#currentbinhud.Elements} -- select this one
   showEditWindow()
   addTableToUndoList(newElem,selected,"create")
   undoButton.enabled = true
   setFileAsChanged()
end

function duplicateButton:onClick()
   if not (#selected == 0) then
      table.insert(currentbinhud.Elements,#currentbinhud.Elements+1,currentbinhud.Elements[selected[1]])
      selected = {#currentbinhud.Elements} -- select this one
      addTableToUndoList(currentbinhud.Elements[selected[1]],selected[1],"create")
      undoButton.enabled = true
   end
end
win:shortcut("d",duplicateButton.onClick,true)

local selectionTolerancy = 4
function Canvas:onClick(x,y)
   lastX,lastY = x,y
   hasClicked = true
   if multiSel.checked == false then
       selected = {} -- if selected nothing
   end
   for elemID=1,#currentbinhud.Elements do
      local elem = currentbinhud.Elements[elemID]
      local ex,ey = Canvas:aspectRatio(elem.X,elem.Y)
      ex,ey = ex-xOff,ey-yOff
      local w,h = elem.Width*(Canvas.width/Canvas.height),elem.Height*(Canvas.width/Canvas.height)
      w,h = w*elem.SizeX,h*elem.SizeY
      if x>ex and x<ex+w and y>ey and y<ey+h or x>ex-selectionTolerancy and x<ex+selectionTolerancy and y>ey-selectionTolerancy and y<ey+selectionTolerancy then
        if multiSel.checked == false then
           selected = {elemID}
        else 
           local state,id = table.equaltoany(selected,elemID)
           if not (state) then
              table.insert(selected,#selected+1,elemID)
           else
              table.remove(selected,id)
           end
        end
      end
   end
end
local holdingmouse = false
local holdingtime = 0
local holdingtimeact = 0.3
local downX,downY = 0,0
function Canvas:onMouseDown(btn,x,y)
   holdingmouse = true
   downX,downY = x,y
end
function Canvas:onMouseUp(btn,x,y)
   holdingmouse = false
   if holdingtime>holdingtimeact then lastX = x lastY = y end
   if not (#selected==0) and holdingtime>holdingtimeact and #selected==1 then
       --print("mov'd")
       local x,y = projectElement(currentbinhud.Elements[selected[1]])
       x,y=x+(lastX-x),y+(lastY-y)
       local rx,ry = x/self.width,y/self.height
       --print(currentbinhud.Elements[selected].X,currentbinhud.Elements[selected].Y,">",rx,ry)
       currentbinhud.Elements[selected[1]].X,currentbinhud.Elements[selected[1]].Y = rx,ry
   elseif #selected>1 and holdingtime>holdingtimeact then
      ui.error("You can only move one element with your mouse at time")
   end
end

win:show()
--Canvas:begin()

function Canvas:grid(x,y,units,color,subcolor,width)
   local x,y = x==nil and 1 or x,y==nil and 1 or y
   local sx,sy = x+units,y+units
   sx = sx == 0 and 1 or sx
   sy = sy == 0 and 1 or sy
   for y=1,Canvas.height,sx do
      for x=1,Canvas.width,sy do
	     self:roundrect(x,y,x+units,y+units,0,0,color or 0xFFFFFFFF,width or 1)
		 self:roundrect(x-2,y-2,x+2,y+2,0,0,subcolor or 0xFFFFFFFF,width or 1)
		 x = x+units
	  end
	  y = y+units
   end
end

--Canvas:show()
--Canvas:begin()

function tocolor(r,g,b,a)
   r,g,b,a=math.floor(r),math.floor(g),math.floor(b),math.floor(a)
   r = r>255 and 255 or r
   g = g>255 and 255 or g
   b = b>255 and 255 or b
   a = a>255 and 255 or a
   r = r<0 and 0 or r
   g = g<0 and 0 or g
   b = b<0 and 0 or b
   a = a<0 and 0 or a   
   local p = string.pack("BBBB",math.floor(r),math.floor(g),math.floor(b),math.floor(a))
   local u = string.unpack("i4",p)
   return u
end

-- Safe area
function setSafeArea(h,v) 
   local rels = cbox_csize.checked
   for elemID=1,#currentbinhud.Elements do
      local elem = currentbinhud.Elements[elemID]
      elem.X = (elem.X*h)+(1-h)/2
      elem.Y = (elem.Y*v)+(1-v)/2
      if rels then
         --elem.SizeX = (elem.SizeX*h)
         --elem.SizeY = (elem.SizeY*v)
         elem.Width = (elem.Width*h)
         elem.Height = (elem.Height*v)
      end
   end
end
function moveAll(x,y)
   for elemID=1,#currentbinhud.Elements do
      local elem = currentbinhud.Elements[elemID]
      elem.X = elem.X+x
      elem.Y = elem.Y+y
   end  
end
function resizeAll(x,y)
   for elemID=1,#currentbinhud.Elements do
      local elem = currentbinhud.Elements[elemID]
      elem.SizeX = elem.SizeX+x
      elem.SizeY = elem.SizeY+y
   end  
end
function btn_set2:onClick()
   if not (tonumber(ent_sfax.text)==nil or tonumber(ent_sfay.text)==nil) and not (tonumber(ent_reax.text)==nil or tonumber(ent_reay.text)==nil) then
      setSafeArea(tonumber(ent_sfax.text),tonumber(ent_sfay.text))
      ui.msg("Safe area & resolution set!")
      currentbinhud.Width = tonumber(ent_reax.text)
      currentbinhud.Height = tonumber(ent_reay.text)
      setFileAsChanged()
   else
      ui.error("Failed to set safe area & resolution, please verify everything and try again!")
   end
end
function btn_set3:onClick()
   if not (tonumber(ent_max.text)==nil or tonumber(ent_may.text)==nil) then
      moveAll(tonumber(ent_max.text),tonumber(ent_may.text))
      ui.msg("Moved!")
      setFileAsChanged()
   else
      ui.error("Failed to move, please verify everything and try again!")
   end
end
function btn_set4:onClick()
   if not (tonumber(ent_rax.text)==nil or tonumber(ent_ray.text)==nil) then
      resizeAll(tonumber(ent_rax.text),tonumber(ent_ray.text))
      ui.msg("Resized!")
      setFileAsChanged()
   else
      ui.error("Failed to resize, please verify everything and try again!")
   end
end

function copyButton:onClick()
   if not (#selected == 0) then
       copied = {} -- clean the list
       for sID=1,#selected do
          table.insert(copied,#copied+1,currentbinhud.Elements[selected[sID]])
       end
       pasteButton.enabled = true
   end
end 

function pasteButton:onClick()
   if not (#copied == 0) then
       local selected = {} -- clean the selected list to unselect all
       for cID=1,#copied do
          table.insert(currentbinhud.Elements,#currentbinhud.Elements+1,copied[cID])
          table.insert(selected,#selected+1,#currentbinhud.Elements+1)
       end      
   end
end
win:shortcut("c",copyButton.onClick,true)
win:shortcut("v",pasteButton.onClick,true)

local white = 0xFFFFFFFF
local red = 0xFF0000FF
local green = 0x00FF00FF
local blue = 0x0000FFFF
--local alpha = true
Canvas.drawing = true
function --[[Canvas:]]onPaint()
   local self = Canvas
   if Canvas.drawing == false then return end
   if holdingmouse == true then holdingtime = holdingtime+0.08 else holdingtime = 0 end
   Canvas:clear()
   if not (grid == "none") then
      Canvas:grid(0,0,grid,0xFFFFFF40,0x00FF005F)
   end
   -- draw elements
   for elemID=1,#currentbinhud.Elements do
      local elem = currentbinhud.Elements[elemID]
      --local a = 255 --math.floor(255*elem.A)
      --if alpha == false then a = 255 end
      --local colorb = string.pack("i4",math.floor(255*elem.R),math.floor(255*elem.G),math.floor(255*elem.B),a)
      --local color = string.unpack("i4",colorb)
      --[[
      local x,y = Canvas:aspectRatio(elem.X,elem.Y)
      x,y = x-xOff,y-yOff
      local w,h = elem.Width*(self.width/self.height),elem.Height*(self.width/self.height)
      w,h = w*elem.SizeX,h*elem.SizeY
      ]]
      local col = tocolor(255*elem.R,255*elem.G,255*elem.B,255*elem.A)
      local noalpha = tocolor(255*elem.R,255*elem.B,255*elem.G,255)
      local isSel = table.equaltoany(selected,elemID) --selected == elemID
      local x,y,w,h = projectElement(elem)
      Canvas:roundrect(x,y,x+w,y+h,0,0,white)
      Canvas:roundrect(x,y,x+w,y+h,0,0,isSel and red or col)
      if isSel then
         Canvas:rect(x,y,x+w,y+h,col)
      end
      --Canvas:rect(x,y,x+w,y+h,0,0,tocolor(255*elem.R,255*elem.G,255*elem.B,128))
      local align = elem.Align
      local ax,ay = x,y
      -- center
      if align == 2 then
         ax,ay = x+(w*0.5),y+(h*0.5)
      end
      -- right up
      if align == 1 then
         ax,ay = x+w,y
      end
      Canvas:cross(ax,ay,10,isSel and red or white,1.5)
      Canvas:print(elemID,ax-5,ay-30,white)
   end
   local sel2 = (#selected>1) and "..." or tostring(selected[#selected])
   local sel = (#selected == 0)  and "Nothing" or sel2
   Canvas:print(self.width.."x"..self.height.." Grid: "..grid.." Selected ID: "..tostring(sel),0,self.height*0.974,white)
   if hasClicked then
      local g = grid == "none" and 30 or grid+5
      local col = holdingtime>holdingtimeact and green or red
      if multiSel.checked == true then col = blue end
      Canvas:line(lastX-g,lastY,lastX+g,lastY,col)
      Canvas:line(lastX,lastY-g,lastX,lastY+g,col)
      Canvas:roundrect(lastX-2,lastY-2,lastX+2,lastY+2,1,1,col)
   end
   Canvas:line(-xOff,-yOff-self.height,-xOff,self.height,white,1)
   Canvas:line(-self.width,-yOff,self.width,-yOff,white,1)
end

function movsel(x,y)
   if not (#selected==0) then
      for selectedid=1,#selected do
         addTableToUndoList(currentbinhud.Elements[selected[selectedid]],selected,"move")
         currentbinhud.Elements[selected[selectedid]].X = currentbinhud.Elements[selected[selectedid]].X+x
         currentbinhud.Elements[selected[selectedid]].Y = currentbinhud.Elements[selected[selectedid]].Y+y
         undoButton.enabled = true
      end
      setFileAsChanged()
   end 
end

function win:onKey(key)
   key = string.lower(key)
   local multi = 1
   if key == "vk_shift" then xOff = 0 yOff = 0 end
   if key == "vk_delete" then deleteButton:onClick() end
   if key == "z" then alpha = not alpha end
   local adv = (grid=="none" and 2 or grid)*multi
   if key == "a" then
      xOff = xOff-adv
      lastX = lastX+adv
   end
   if key == "d" then
      xOff = xOff+adv
      lastX = lastX-adv
   end
   if key == "w" then
      yOff = yOff-adv
      lastY = lastY+adv
   end
   if key == "s" then
      yOff = yOff+adv
      lastY = lastY-adv
   end
   if key == "vk_left" then
       movsel(-adv/Canvas.width,0)
   end
   if key == "vk_right" then
       movsel(adv/Canvas.width,0)
   end
   if key == "vk_up" then
       movsel(0,-adv/Canvas.height)
   end
   if key == "vk_down" then
       movsel(0,adv/Canvas.height)
   end
end

function win:onResize()
   -- --[[Canvas:]]onPaint()
end

function openButton:onClick()
   local dialog = table.concat(supportedFormats,"|")
   local file = ui.opendialog("Open binary HUD file",nil,dialog)
   if file then
    local f = file:open()
	  local verbuffer = f:read(2)
    local ver
    if #verbuffer>=2 then
	     ver = string.unpack("I2",verbuffer)
    else
       ui.error("Error:\n== Out of memory ==\n\tVersion buffer cannot be smaller than 2 bytes","Error")
       file:close()
       return
    end
	  if not (table.equaltoany(supportedVersion,ver)) then
	     ui.error("Unsupported version "..tostring(ver==nil and 0 or ver).."!")
       return
	  end
	  local buffer = f:read(file.size+16)
	  currentbinhud = binaryHUDFile(buffer,ver)
	  if type(currentbinhud)=="table" then
	     --ui.info("Success opening binary HUD file!") -- kind of annoying message
       win.title = string.format("%s - %s",programtitle,file.fullpath)
       selected = {}
       closeButton.enabled = true
       --saveButton.enabled = true
       --saveAsButton.enabled = true
       ent_reax.text = currentbinhud.Width
       ent_reay.text = currentbinhud.Height
       --[[Canvas:]]onPaint()
      else
	     ui.error("Error opening binary HUD file!\n"..tostring(currentbinhud))
       currentbinhud = noBinaryHUDFile()
       --[[Canvas:]]onPaint()
	  end
    lastfile = file
    file:close()
   else
       -- nothing?
   end
end

repeat
   Canvas:begin()
   Canvas:clear()
   onPaint()
   Canvas:flip()
   --onPaint()
   --local t = os.clock()  
   ui.update()
   --local dt = (t-os.clock())/100
until not win.visible