
---------------------------------------------- GAME CLASS ----------------------------------------------------------------------------------------------
Game = {}
Game.__index = Game

function Game:New(title, ids, framebuffer, internal, frameps)
    local this = 
    {
        name = title,
        id = ids,
        fb = framebuffer,
        ib = internal,
        fps = frameps,
        enabled = 1,
        osd = 1,
        default_fb = framebuffer,
        default_ib = internal,
        default_fps = frameps,
        europe = false,
        usa = false,
        japan = false,
        asia = false
    }

    setmetatable(this, Game)
    return this
end
---------------------------------------------------------- VARIABLE AND FUNCTION SETUP ----------------------------------------------------------------------
--Initializing Global Variables
games = {} -- Game List
gameCounter = 1 -- Number of games counter

game_list = "" -- gamelist.txt text
config_text = "" -- config.txt text

main_enable = 1 --VitaGrafix Enable Override
main_osd = 1 --VitaGrafix OSD Override

-- Button Variables
fb_button = nil
ib_button = nil
fps_button = nil
save_button = nil

selected_button = 0
available_buttons = 0

-- Selection Rectangle Variables
selectionRectX = 5
selectionRectY = 150
selectionWidth = 240
selectionHeight = 20

-- Text scroll variables
textX = 350
textChar = 0
textCharMax = 25

scrollTimer = Timer.new()
isScrolling = false
isWaitingToScroll = false

pad = 0 -- Controller
previousPad = 0 -- Controller previous state, used to check if a button was just pressed, or if it is held down

needsToGetVersion = true
result = ""
list_version = ""
app_version = ""
list_v_num = 0
app_v_num = 0
app_folder = "VGCF00001"

timerObj = Timer.new()

-- Set Buttons to nil each frame
function NilButtons()
  fb_button = nil
  ib_button = nil
  fps_button = nil
  save_button = nil
end

function DownloadFile(str)
  -- Opening a new socket and connecting to the host
  skt = Socket.connect("vgcfvita.000webhostapp.com", 80)

  -- Our payload to request a file
  payload = "GET /" .. str .. " HTTP/1.1\r\nHost: vgcfvita.000webhostapp.com\r\n\r\n"

  -- Sending request
  Socket.send(skt, payload)

  -- Since sockets are non blocking, we wait till at least a byte is received
  raw_data = ""
  retry = 0
  while raw_data == "" or retry < 1000 do
    raw_data = raw_data .. Socket.receive(skt, 8192)
    retry = retry + 1
  end

  if string.match(raw_data, "Length: ") then
    -- Keep downloading till the whole response is received
    dwnld_data = raw_data
    retry = 0
    while dwnld_data ~= "" or retry < 1000 do
      dwnld_data = Socket.receive(skt, 8192)
      raw_data = raw_data .. dwnld_data
      if dwnld_data == "" then
        retry = retry + 1
      else
        retry = 0
      end
    end

    -- Extracting Content-Length value
    offs1, offs2 = string.find(raw_data, "Length: ")
    offs3 = string.find(raw_data, "\r", offs2)
    content_length = tonumber(string.sub(raw_data, offs2, offs3))

    -- Saving downloaded image
    stub, content_offset = string.find(raw_data, "\r\n\r\n")
    handle = System.openFile("ux0:data/new_".. str, FCREATE)
    content = string.sub(raw_data, content_offset+1)
    System.writeFile(handle, string.sub(raw_data, content_offset+1), string.len(content))
    System.closeFile(handle)

  else
    Socket.close(skt)
    return -1
  end
  -- Closing socket
  Socket.close(skt)
  return 1
end


function GetLocalVersion()

  local file = System.openFile("app0:/versions.txt", FREAD)
  System.seekFile(file, 0, SET)
  local version_text = System.readFile(file, System.sizeFile(file))
  System.closeFile(file)

  local i,j = string.find(version_text, "gamelist=%d+%.%d+")
  list_version = string.sub(version_text, i, j)
  local list_version_num = GetNumber(list_version)

  i,j = string.find(version_text, "app=%d+%.%d+")
  app_version = string.sub(version_text, i, j)
  local app_version_num = GetNumber(app_version)

  if not System.doesFileExist("ux0:data/Vitagrafix/versions.txt") then
    file = System.openFile("ux0:data/Vitagrafix/versions.txt", FCREATE)
    System.writeFile(file, version_text, string.len(version_text))
    System.closeFile(file)
    return
  end

  file = System.openFile("ux0:data/Vitagrafix/versions.txt", FREAD)
  System.seekFile(file, 0, SET)
  local ux_version_text = System.readFile(file, System.sizeFile(file))
  System.closeFile(file)

  local i,j = string.find(ux_version_text, "gamelist=%d+%.%d+")
  ux_list_version = string.sub(ux_version_text, i, j)
  local ux_list_version_num = GetNumber(ux_list_version)

  i,j = string.find(ux_version_text, "app=%d+%.%d+")
  ux_app_version = string.sub(ux_version_text, i, j)
  local ux_app_version_num = GetNumber(ux_app_version)

  if list_version_num > ux_list_version_num or app_version_num > ux_app_version_num then
    file = System.openFile("ux0:data/Vitagrafix/versions.txt", FCREATE)
    System.writeFile(file, version_text, string.len(version_text))
    System.closeFile(file)
  end



end

function GetVersion()
  
  GetLocalVersion()
  local file = System.openFile("ux0:/data/VitaGrafix/versions.txt", FREAD)
  System.seekFile(file, 0, SET)
  local version_text = System.readFile(file, System.sizeFile(file))
  System.closeFile(file)

  local i,j = string.find(version_text, "gamelist=%d+%.%d+")
  list_version = string.sub(version_text, i, j)
  local list_version_num = GetNumber(list_version)

  i,j = string.find(version_text, "app=%d+%.%d+")
  app_version = string.sub(version_text, i, j)
  local app_version_num = GetNumber(app_version)

  -- Initializing Network
  Network.init()

  -- Checking if connection is available
  if Network.isWifiEnabled() then

    if DownloadFile("versions.txt") == 1 then

      -- Loading image in memory and deleting it from storage
      local new_version_file = System.openFile("ux0:data/new_versions.txt", FREAD)
      System.seekFile(new_version_file, 0, SET)
      local new_version_text = System.readFile(new_version_file, System.sizeFile(new_version_file))
      System.closeFile(new_version_file)
      result = new_version_text
      System.deleteFile("ux0:/data/new_versions.txt")

      i,j = string.find(new_version_text, "gamelist=%d+%.%d+")
      local new_list_version = string.sub(new_version_text, i, j)
      i,j = string.find(new_version_text, "app=%d+%.%d+")
      local new_app_version = string.sub(new_version_text, i, j)

      local new_list_number = GetNumber(new_list_version)
      local new_app_number = GetNumber(new_app_version)
      
      --if not string.match(new_app_version, app_version) then 

      if not string.match(new_list_version, list_version) then
        local wantsToUpdate = 0
        
        while wantsToUpdate == 0 do

          EndDraw()
          BeginDraw()

          pad = Controls.read()
          Graphics.debugPrint(250, 192, "New game list version found, do you want to update?", Color.new(255,255,255))
          Graphics.debugPrint(280, 232, "Current Version: " .. tostring(list_version_num) .. "  New Version: " .. tostring(new_list_number), Color.new(255,255,255))
          Graphics.debugPrint(350, 262, "Cross: Yes   Circle: No", Color.new(255,255,255))

          if pad ~= previousPad then
            if Controls.check(pad, SCE_CTRL_CROSS) then
              wantsToUpdate = 1
            elseif Controls.check(pad, SCE_CTRL_CIRCLE) then
              wantsToUpdate = 2
            end
          end

          previousPad = pad
          EndDraw()

        end

        if wantsToUpdate == 1 then
          if DownloadFile("gamelist.txt") == 1 then
            local new_game_list = System.openFile("ux0:data/new_gamelist.txt", FREAD)
            System.seekFile(new_game_list, 0, SET)
            local new_list_text = System.readFile(new_game_list, System.sizeFile(new_game_list))
            System.closeFile(new_game_list)
            System.deleteFile("ux0:data/new_gamelist.txt")
            new_game_list = System.openFile("ux0:data/VitaGrafix/gamelist.txt", FCREATE)
            System.writeFile(new_game_list, new_list_text, string.len(new_list_text))
            System.closeFile(new_game_list)
            games = {}
            gameCounter = 1
            Start()

            file = System.openFile("ux0:data/Vitagrafix/versions.txt", FCREATE)
            System.writeFile(file, new_version_text, string.len(new_version_text))
            System.closeFile(file)
          else
            EndDraw()
            BeginDraw()
            Graphics.debugPrint(250, 192, "Error while downloading lists", Color.new(255,255,255))
            EndDraw()
            System.wait(1000000)
          end
        end
      end
    else
      EndDraw()
      BeginDraw()
      Graphics.debugPrint(250, 192, "Error while checking version", Color.new(255,255,255))
      EndDraw()
      System.wait(1000000)
    end

  end

  Network.term()

  local file = System.openFile("ux0:/data/VitaGrafix/versions.txt", FREAD)
  System.seekFile(file, 0, SET)
  local version_text = System.readFile(file, System.sizeFile(file))
  System.closeFile(file)

  local i,j = string.find(version_text, "gamelist=%d+%.%d+")
  list_version = string.sub(version_text, i, j)
  list_v_num = GetNumber(list_version)

  i,j = string.find(version_text, "app=%d+%.%d+")
  app_version = string.sub(version_text, i, j)
  app_v_num = GetNumber(app_version)


end

function GetNumber(str)
    local i,j = string.find(str, "%d+%.%d+")
    local number = tonumber(string.sub(str, i, j))
    return number
end

-- Draw the selection rect
function DrawSelectionRect()
  Graphics.fillRect(selectionRectX, selectionRectX + selectionWidth, selectionRectY, selectionRectY + selectionHeight, Color.new(0,0,255)) 
end

-- 1 to 0 and 0 to 1 "bool" switcher
function SwitchBool(b)
  if b == 1 then
    return 0
  else
    return 1
  end
end


-- Get Single game supported regions
function GetLocations(game)
  for i = 1, #game.id, 1 do
    if string.match( game.id[i],  "PCSE") or string.match( game.id[i],  "PCSA") then
      game.usa = true
    elseif string.match( game.id[i],  "PCSF") or string.match( game.id[i],  "PCSB") then
      game.europe = true
    elseif string.match( game.id[i],  "PCSH") or string.match( game.id[i],  "VCAS") or string.match( game.id[i],  "VLAS") then
      game.asia = true
    elseif string.match( game.id[i],  "PCSC") or string.match( game.id[i],  "VCJS") or string.match( game.id[i],  "PCSG") or string.match( game.id[i],  "VLJS") or string.match( game.id[i],  "VLJM") then
      game.japan = true
    end
  end
end

-- Get All games supported regions
function GetRegions()
  for i = 1, #games, 1 do
    GetLocations(games[i])
  end
end

-- Get Parameters for one game on the gamelist.txt file
function ReadGameParams(startPoint)
  local name = ""
  local ids = {}
  local fb = ""
  local ib = ""
  local fps = ""

  local i,j = string.find(game_list, "%[(.-)%]", startPoint) -- Get game name

  if i ~= nil then
    name = string.sub(game_list, i+1, j-1)
    local k,l = string.find(game_list, "ID=", j)
    local delim = ","
    local counter = 1

    -- Get Game IDs
    while delim == "," do
      local id = string.sub(game_list, l+1, l+9)
      ids[counter] = id
      l = l+10
      delim = string.sub(game_list, l, l)
      counter = counter+1
    end

    -- Get game Framebuffer
    k,l = string.find(game_list, "FB=", l)
    if string.match(string.sub(game_list, l+1, l+5), "false") then
      fb = "false"
    else
      delim = ","
      while delim ~= "\n" do
        
        fb = fb .. string.sub(game_list, l+1, l+1)
        l = l + 1
        delim = string.sub(game_list, l+1, l+1)
      end
    end
 
    -- Get Game Internal Resolution
    k,l = string.find(game_list, "IB=", l)
    
    if string.match(string.sub(game_list, l+1, l+5), "false") then
      ib = "false"
    else
      delim = ","
      while delim ~= "\n" do
        ib = ib .. string.sub(game_list, l+1, l+1)
        l = l + 1
        delim = string.sub(game_list, l+1, l+1)
      end
    end

     -- Get Game Frames Per Second Cap
    k,l = string.find(game_list, "FPS=", l)
    if string.match(string.sub(game_list, l+1, l+5), "false") then
      fps = "false"
    else
      delim = ","
      while l < string.len( game_list ) and delim ~= "\n" do
        fps = fps .. string.sub(game_list, l+1, l+1)
        l = l + 1
        delim = string.sub(game_list, l+1, l+1)
      end
    end
    return name, ids, fb, ib, fps, j
  end
  return false
end

-- Add games to the game list
function CreateGameList()
  System.createDirectory("ux0:data/VitaGrafix")
  if not System.doesFileExist("ux0:data/VitaGrafix/gamelist.txt") then
    local original_file = System.openFile("app0:/gamelist.txt", FREAD)
    System.seekFile(original_file, 0, SET)
    game_list = System.readFile(original_file, System.sizeFile(original_file))
    System.closeFile(original_file)
    local new_file = System.openFile("ux0:data/VitaGrafix/gamelist.txt", FCREATE)
    System.writeFile(new_file, game_list, string.len(game_list))
    System.closeFile(new_file)

  end
  local file = System.openFile("ux0:data/VitaGrafix/gamelist.txt", FREAD)
  System.seekFile(file, 0, SET)
  game_list = System.readFile(file, System.sizeFile(file)) 
  local name, ids, fb, ib, fps, point = ReadGameParams(0) -- Read First Game Parameters
  while name ~= false do -- While there is a game, keep adding games to the list
    games[gameCounter] = Game:New(name, ids, fb, ib, fps, 0) -- Needs extra 0 or function bugs out and parameters go to the wrong variables
    gameCounter = gameCounter + 1
    name, ids, fb, ib, fps, point = ReadGameParams(point)
  end
  System.closeFile(file)
  gameCounter = 0 -- Set Game counter to 0 as it's now going to be used as our game selector on the menu
end

-- Finds current settings for all games
function FindCurrentSettings()
  
  local file = nil
  if System.doesFileExist("ux0:data/VitaGrafix/config.txt") then
    file = System.openFile("ux0:data/VitaGrafix/config.txt", FREAD)
    System.seekFile(file, 0, SET)
    config_text = System.readFile(file, System.sizeFile(file))
    System.closeFile(file)

    -- Find Main VitaGrafix Settings
    local t,y = string.find(config_text, "%[MAIN%]")
    if t ~= nil then
      t,y = string.find(config_text, "ENABLED=", y)
      if t ~= nil then
        local enabled = string.sub(config_text, y+1, y+1)
        main_enable = tonumber(enabled)
      end
      t,y = string.find(config_text, "OSD=", y)
      if t ~= nil then
        local osd = string.sub(config_text, y+1, y+1)
        main_osd = tonumber(osd)
      end
    end

    -- Find game settings
    for i = 1, #games, 1 do -- game for

      for j = 1, #games[i].id do -- id for

        local k,l = string.find(config_text,"%["..games[i].id[j].."%]")

        if k ~= nil then
          local start = k+1
          k,l = string.find(config_text,"%[", l)
          if k ~= nil then
            local pre_text = string.sub(config_text, start, l)
            k,l = string.find(pre_text, "ENABLED=")
            if k ~= nil then
              local enabled = string.sub(pre_text, l+1, l+1)
              games[i].enabled = tonumber(enabled)
            end
            k,l = string.find(pre_text, "OSD=")
            if k ~= nil then
              local osd = string.sub(pre_text, l+1, l+1)
              games[i].osd = tonumber(osd)
            end
            k,l = string.find(pre_text, "FB=")
            if k ~= nil then
              delim = ","
              local fb = ""
              while l < string.len(pre_text) and delim ~= "\n" do
                
                fb = fb .. string.sub(pre_text, l+1, l+1)
                l = l + 1
                delim = string.sub(pre_text, l+1, l+1)
              end
              games[i].fb = fb
            end

            k,l = string.find(pre_text, "IB=")
            if k ~= nil then
              delim = ","
              local ib = ""
              while l < string.len(pre_text) and delim ~= "\n" do
                ib = ib .. string.sub(pre_text, l+1, l+1)
                l = l + 1
                delim = string.sub(pre_text, l+1, l+1)
              end
              games[i].ib = ib
            end
        
            k,l = string.find(pre_text, "FPS=")
            if k ~= nil then
              local fps = ""
              delim = ","
              while l < string.len( pre_text ) and delim ~= "\n" do
                fps = fps .. string.sub(pre_text, l+1, l+1)
                l = l + 1
                delim = string.sub(pre_text, l+1, l+1)
              end
              games[i].fps = fps
            end

          end

          break
        end -- end id for

      end -- end game for

    end -- end file check if
  end

end

-- Get Default VitaGrafix Settings for each game
function GetDefault(game, str)
  if string.match( str, "FB" ) then
    return game.default_fb
  elseif string.match( str, "IB" ) then
    return game.default_ib
  elseif string.match( str, "FPS" ) then
    return game.default_fps
  end
end

-- Update one game on the config file.
function WriteSingleGame(game)
  
  for i = 1, #game.id, 1 do
    
    config_text = config_text .. "\n[" .. game.id[i] .. "]"

    config_text = config_text .. "\nENABLED=" .. game.enabled
    config_text = config_text .. "\nOSD=" .. game.osd

    if game.fb ~= "false" then
      config_text = config_text .. "\nFB=" .. game.fb
    end

    if game.ib ~= "false" then
      config_text = config_text .. "\nIB=" .. game.ib
    end

    if game.fps ~= "false" then
      config_text = config_text .. "\nFPS=" .. game.fps
    end

    config_text = config_text .. "\n"

  end
end

-- Update the entire config.txt file
function WriteToFile()
  local file = System.openFile("ux0:/data/VitaGrafix/config.txt", FCREATE)
  config_text = ""
  config_text = config_text .. "[MAIN]"
  config_text = config_text .. "\nENABLED=" .. main_enable
  config_text = config_text .. "\nOSD=" .. main_osd
  config_text = config_text .. "\n"
  for i = 1, #games, 1 do
    WriteSingleGame(games[i])
  end
  System.writeFile(file, config_text, string.len(config_text))

end

-- Draw functions
function BeginDraw ()
  Graphics.initBlend()
  if Keyboard.getState() ~= RUNNING then
    Screen.clear()
  end
end

function EndDraw()
  Screen.flip() 
  Graphics.termBlend() 
end

-- Make the text scroll if game has a large name
function MoveText()

  -- Wait 2 seconds before scrolling
  if Timer.getTime(scrollTimer) >= 2000 and isScrolling == false and isWaitingToScroll == false then
    isScrolling = true
    textChar = textCharMax - 24
    Timer.reset(scrollTimer)
  end

  -- Scroll Text
  if isScrolling then
    if textChar > 0 then
      textX = textX - 1
      if Timer.getTime(scrollTimer) >= 400 then
        
        textChar = textChar - 1
        Timer.reset(scrollTimer)
      end
    else
      isScrolling = false
      isWaitingToScroll = true
      Timer.reset(scrollTimer)
    end
  end

  -- Wait 2 seconds before setting the text back to original position
  if isWaitingToScroll then
    if Timer.getTime(scrollTimer) >= 2000 then
      textX = 350
      Timer.reset(scrollTimer)
      isWaitingToScroll = false
    end
  end

end

-- Reset the scrolling variables
function SetScrollVars()
  Timer.reset(scrollTimer)
  textX = 350
  textCharMax = 25
  textChar = 0
  isScrolling = false
  isWaitingToScroll = false
end

-- GUI Drawing function
function GUI()

  NilButtons()

 -- Update the selection rectangle to the position of the selected button and draw it
  
  if selected_button ~= 0 then 
    selectionRectY = 150 + 30*(selected_button-1)
    selectionRectX = 5
  else
    selectionRectY = 80
    selectionRectX = 350
  end

  DrawSelectionRect()


  local max_len = 25 -- Max text length for side texts
  local objectNum = 0 -- Number of clickables buttons on the screen

  Graphics.debugPrint(5, 10, "VitaGrafix Configurator", Color.new(255,255,255))

  Graphics.debugPrint(300, 10, "List: " .. tostring(list_v_num), Color.new(255,255,255))
  Graphics.debugPrint(400, 10, "App: " .. tostring(app_v_num), Color.new(255,255,255))

 
  if gameCounter == 0 then  -- If on VitaGrafix settings
    Graphics.debugPrint(350, 80, "VitaGrafix Settings", Color.new(255,255,255))

    if string.len(games[#games].name) < 25 then
      max_len = string.len(games[#games].name)
    end

    Graphics.debugPrint(5, 80, string.sub(games[#games].name, 0, max_len), Color.new(150,150,150))

    max_len = 25
    if string.len(games[1].name) < 25 then
      max_len = string.len(games[1].name)
    end

    Graphics.debugPrint(650, 80, string.sub(games[1].name, 0, max_len), Color.new(150,150,150))

    Graphics.debugPrint(5, 150, "Enabled", Color.new(255,255,255))
    Graphics.debugPrint(5, 180, "OSD", Color.new(255,255,255))

    if main_enable == 1 then
      Graphics.debugPrint(250, 150, "X", Color.new(255,255,255))
    else
      Graphics.debugPrint(250, 150, "", Color.new(255,255,255))
    end

    if main_osd == 1 then
      Graphics.debugPrint(250, 180, "X", Color.new(255,255,255))
    else
      Graphics.debugPrint(250, 180, "", Color.new(255,255,255))
    end



    objectNum = 2

    Graphics.debugPrint(5, 150 + 30 * objectNum, "Save Config", Color.new(255,255,255))
    save_button = objectNum + 1

    available_buttons = 3

  else -- If on any game
    
    
    textCharMax = string.len(games[gameCounter].name)

    Graphics.debugPrint(textX, 80, games[gameCounter].name, Color.new(255,255,255))

    -- Black Rects to hide text while scrolling
    Graphics.fillRect(0, 350, 70, 110, Color.new(0,0,0))
    Graphics.fillRect(600, 960, 70, 110, Color.new(0,0,0))

    if gameCounter == 1 then
      Graphics.debugPrint(5, 80, "VitaGrafix Settings", Color.new(150,150,150))
    else
      max_len = 25
      if string.len(games[gameCounter-1].name) < 25 then
        max_len = string.len(games[gameCounter-1].name)
      end
      Graphics.debugPrint(5, 80, string.sub(games[gameCounter-1].name, 0, max_len), Color.new(150,150,150))
    end
    
    if gameCounter == #games then
      Graphics.debugPrint(650, 80, "VitaGrafix Settings", Color.new(150,150,150))
    else
      max_len = 25
      if string.len(games[gameCounter+1].name) < 25 then
        max_len = string.len(games[gameCounter+1].name)
      end
      Graphics.debugPrint(650, 80, string.sub(games[gameCounter+1].name, 0, max_len), Color.new(150,150,150))
    end
    
    Graphics.debugPrint(5, 150 + 30 * objectNum, "Enabled", Color.new(255,255,255))
    objectNum = objectNum + 1
    Graphics.debugPrint(5, 150 + 30 * objectNum, "OSD", Color.new(255,255,255))
    objectNum = objectNum + 1

    if games[gameCounter].enabled == 1 then
      Graphics.debugPrint(250, 150, "X", Color.new(255,255,255))
    else
      Graphics.debugPrint(250, 150, "", Color.new(255,255,255))
    end

    if games[gameCounter].osd == 1 then
      Graphics.debugPrint(250, 180, "X", Color.new(255,255,255))
    else
      Graphics.debugPrint(250, 180, "", Color.new(255,255,255))
    end

    if games[gameCounter].fb ~= "false" then
      Graphics.debugPrint(5, 150 + 30 * objectNum, "Framebuffer", Color.new(255,255,255))
      Graphics.debugPrint(250, 150 + 30 * objectNum, games[gameCounter].fb, Color.new(255,255,255))
      Graphics.debugPrint(400, 150 + 30 * objectNum, "(Default: " .. games[gameCounter].default_fb .. ")", Color.new(255,255,255)) 
      objectNum = objectNum + 1
      fb_button = objectNum
    end

    if games[gameCounter].ib ~= "false" then
      Graphics.debugPrint(5, 150 + 30 * objectNum, "Internal Resolution", Color.new(255,255,255))
      Graphics.debugPrint(250, 150 + 30 * objectNum, games[gameCounter].ib, Color.new(255,255,255))
      Graphics.debugPrint(400, 150 + 30 * objectNum, "(Default: " .. games[gameCounter].default_ib .. ")", Color.new(255,255,255))
      objectNum = objectNum + 1
      ib_button = objectNum
    end

    if games[gameCounter].fps ~= "false" then
      Graphics.debugPrint(5, 150 + 30 * objectNum, "FPS Cap", Color.new(255,255,255))
      Graphics.debugPrint(250, 150 + 30 * objectNum, games[gameCounter].fps, Color.new(255,255,255))
      Graphics.debugPrint(400, 150 + 30 * objectNum, "(Default: " .. games[gameCounter].default_fps .. ")", Color.new(255,255,255))
      objectNum = objectNum + 1
      fps_button = objectNum
    end

    Graphics.debugPrint(5, 150 + 30 * objectNum, "Save Config", Color.new(255,255,255))
    objectNum = objectNum + 1
    save_button = objectNum

    available_buttons = objectNum
    local region_text = "Regions Supported: "
    if(games[gameCounter].europe) then
      region_text = region_text .. "[Europe] "
    end
    if(games[gameCounter].usa) then
      region_text = region_text .. "[USA] "
    end
    if(games[gameCounter].japan) then
      region_text = region_text .. "[Japan] "
    end
    if(games[gameCounter].Asia) then
      region_text = region_text .. "[Asia] "
    end
    Graphics.debugPrint(5, 360, region_text, Color.new(255,255,255))
  end

  if selected_button > 2 and selected_button < available_buttons then
    Graphics.debugPrint(600, 10, "Press Triangle for default setting", Color.new(255,255,255))
  end

end

-- Function called when X was pressed
function CrossPressed()
  if selected_button == 1 then -- Button 1 is the enabled option
    if gameCounter == 0 then
      main_enable = SwitchBool(main_enable)
    else
      games[gameCounter].enabled = SwitchBool(games[gameCounter].enabled)
    end
  elseif selected_button == 2 then -- Button 2 is the OSD option
    if gameCounter == 0 then
      main_osd = SwitchBool(main_osd)
    else
      games[gameCounter].osd = SwitchBool(games[gameCounter].osd)
    end
  elseif selected_button == ib_button then -- Internal res button, opens keyboard
    Keyboard.clear()
    Keyboard.show("0 < X <= 960 and 0 < Y <= 544 or OFF", games[gameCounter].ib, 7, TYPE_DEFAULT, MODE_TEXT)
  elseif selected_button == save_button then -- Save button, saves ENTIRE CONFIG (not game specific changes)
    WriteToFile()
    EndDraw()
    BeginDraw()
    Graphics.debugPrint(350, 252, "Configuration Saved!", Color.new(255,255,255))
    EndDraw()

    System.wait(1000000)
  end
end

-- function called when Triangle is pressed. Sets values back to their default ones
function TrianglePressed()
  
  if selected_button == ib_button then
   games[gameCounter].ib = games[gameCounter].default_ib
  elseif selected_button == fb_button then
    games[gameCounter].fb = games[gameCounter].default_fb
  elseif selected_button == fps_button then
    games[gameCounter].fps = games[gameCounter].default_fps
  end
end

-- Function called when up or down are pressed, dir = -1 is left and dir = 1 is right
function DirectionPressed(dir)
  if selected_button == 0 then -- Button 0 is the game list
    if dir == -1 then 
      if gameCounter > 0 then
        gameCounter = gameCounter - 1
      elseif gameCounter == 0 then
        gameCounter = #games
      end
      SetScrollVars()
    else
      if gameCounter < #games then
        gameCounter = gameCounter + 1
      elseif gameCounter == #games then
        gameCounter = 0
      end
      SetScrollVars()
    end

  elseif selected_button == fb_button then -- Change Framebuffer res between the supported modes

    if string.match(games[gameCounter].fb, "960x544") then
      if dir == -1 then
        games[gameCounter].fb = "720x408"
      else
        games[gameCounter].fb = "OFF"
      end 
    elseif string.match(games[gameCounter].fb, "720x408") then
      if dir == -1 then
        games[gameCounter].fb = "640x368"
      else
        games[gameCounter].fb = "960x544"
      end 
    elseif string.match(games[gameCounter].fb, "640x368") then
      if dir == -1 then
        games[gameCounter].fb = "OFF"
      else
        games[gameCounter].fb = "720x408"
      end 
    elseif string.match(games[gameCounter].fb, "OFF") then
      if dir == -1 then
        games[gameCounter].fb = "960x544"
      else
        games[gameCounter].fb = "640x368"
      end 
    end

  elseif selected_button == fps_button then -- Change FPS Cap between the supported modes

    if string.match(games[gameCounter].fps, "60") then
      if dir == -1 then
        games[gameCounter].fps = "30"
      else
        games[gameCounter].fps = "OFF"
      end 
    elseif string.match(games[gameCounter].fps, "30") then
      if dir == -1 then
        games[gameCounter].fps = "OFF"
      else
        games[gameCounter].fps = "60"
      end 
    elseif string.match(games[gameCounter].fps, "OFF") then
      if dir == -1 then
        games[gameCounter].fps = "60"
      else
        games[gameCounter].fps = "30"
      end 
    end
  end
end

-- Initialization function
function Start()
  CreateGameList()
  FindCurrentSettings()
  GetRegions()
  WriteToFile()
  --GetVersion()
end

------------------------------------------------------------------------------------------------- Code Execution ----------------------------------------------------------------------------

Start()

-- Update Loop
while true do
  
  -- Run the update at 60 FPS
  if (Timer.getTime(timerObj) >= 16.7) then
    
    Timer.reset(timerObj)

    if needsToGetVersion then
      GetVersion()
      needsToGetVersion = false
    end

    if System.getAsyncState() == 1 then
      result = System.getAsyncResult()
    end 

    BeginDraw()
    if Keyboard.getState() ~= RUNNING then 
      
      if selected_button > available_buttons then
        selected_button = available_buttons
      end

      MoveText()
      GUI()

      -- Read what controls are pressed
      pad = Controls.read()
    
      -- Check if a button was just pressed and not held
      if(previousPad ~= pad) then
        if Controls.check(pad, SCE_CTRL_LTRIGGER) then
          if gameCounter > 0 then
            gameCounter = gameCounter - 1
          elseif gameCounter == 0 then
            gameCounter = #games
          end
          SetScrollVars()
        end

        if Controls.check(pad, SCE_CTRL_RTRIGGER) then
          if gameCounter < #games then
            gameCounter = gameCounter + 1
          elseif gameCounter == #games then
            gameCounter = 0
          end
          SetScrollVars()
        end

        if Controls.check(pad, SCE_CTRL_CROSS) then
          CrossPressed()
        end

        if Controls.check(pad, SCE_CTRL_TRIANGLE) then
          TrianglePressed()
        end

        if Controls.check(pad, SCE_CTRL_LEFT) then
          DirectionPressed(-1)
        end

        if Controls.check(pad, SCE_CTRL_RIGHT) then
          DirectionPressed(1)
        end

        if Controls.check(pad, SCE_CTRL_UP) then
          if selected_button > 0 then
            selected_button = selected_button - 1
          end
        end

        if Controls.check(pad, SCE_CTRL_DOWN) then
          if selected_button < available_buttons  then
            selected_button = selected_button + 1
          end
        end

      end

      
    end
    
    -- Check if the keyboard is done and set the text to the keyboard input
    if Keyboard.getState() == FINISHED then
      local new_ib = Keyboard.getInput()
      if string.match(string.upper( new_ib ), "OFF") then
        new_ib = "OFF"
      else
        new_ib = string.lower( new_ib )
      end
      if gameCounter ~= 0 then
        games[gameCounter].ib = new_ib
      end
      Keyboard.clear()
    end
    
    previousPad = pad
    EndDraw()
  end

 
end