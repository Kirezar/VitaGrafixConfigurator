
---------------------------------------------- GAME CLASS ----------------------------------------------------------------------------------------------
Game = {}
Game.__index = Game

function Game:New(title, ids, framebuffer, internal, frameps, multisampleAA, pfileUse, pfileName)
    local this = 
    {
        name = title,
        id = ids,
        fb = framebuffer,
        ib = internal,
        fps = frameps,
        msaa = multisampleAA,
        enabled = 1,
        osd = 1,
        default_fb = framebuffer,
        default_ib = internal,
        default_fps = frameps,
        default_msaa = multisampleAA,
        europe = false,
        usa = false,
        japan = false,
        asia = false,
        usesPatchfile = pfileUse,
        patchFile = pfileName

    }

    setmetatable(this, Game)
    return this
end
---------------------------------------------------------- VARIABLE AND FUNCTION SETUP ----------------------------------------------------------------------
--Initializing Global Variables
games = {} -- Game List
gameCounter = 1 -- Number of games counter

game_list = "" -- patchlist.txt text
config_text = "" -- config.txt text

main_enable = 1 --VitaGrafix Enable Override
main_osd = 1 --VitaGrafix OSD Override

-- Button Variables
fb_button = nil
ib_button = nil
fps_button = nil
msaa_button = nil
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

checkForUpgrade = false
result = ""
list_version = ""
app_version = ""
list_v_num = 0
app_v_num = 0
app_folder = "VGCF00001"

auto_update = false
display_installed = false

current_version = true

finished_successfuly = true

timerObj = Timer.new()

installedGamesList = {} -- List to save installed games, used for the displaying only installed games option

-- Navigation ids, help with displaying installed games only
leftGameId = 0
rightGameId = 0

-- Set Buttons to nil each frame
function NilButtons()
  fb_button = nil
  ib_button = nil
  fps_button = nil
  msaa_button = nil
  save_button = nil
end

function ReadAppConfig()

  local file = nil
  if System.doesFileExist("ux0:data/VitaGrafix/appconfig.txt") == false then
    file = System.openFile("ux0:data/VitaGrafix/appconfig.txt", FCREATE)
    local str = "display_installed=0"
    System.writeFile(file, str, string.len(str))
    System.closeFile(file)
  end
  file = System.openFile("ux0:data/VitaGrafix/appconfig.txt", FREAD)
  System.seekFile(file, 0, SET)
  local app_cfg = System.readFile(file, System.sizeFile(file))
  System.closeFile(file)

  if string.match( app_cfg, "display_installed=1") then
    display_installed = true
  else
    file = System.openFile("ux0:data/VitaGrafix/appconfig.txt", FCREATE)
    local str = "display_installed=0"
    System.writeFile(file, str, string.len(str))
    System.closeFile(file)
  end

end

function WriteAppConfig()
  local file = System.openFile("ux0:data/VitaGrafix/appconfig.txt", FCREATE)
  local str = "display_installed="
  if display_installed then
    str = str .. 1
  else
    str = str .. 0
  end
  System.writeFile(file, str, string.len(str))
  System.closeFile(file)
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

  if not System.doesFileExist("ux0:data/VitaGrafix/versions.txt") then
    file = System.openFile("ux0:data/VitaGrafix/versions.txt", FCREATE)
    System.writeFile(file, version_text, string.len(version_text))
    System.closeFile(file)
    return
  end

  file = System.openFile("ux0:data/VitaGrafix/versions.txt", FREAD)
  System.seekFile(file, 0, SET)
  local ux_version_text = System.readFile(file, System.sizeFile(file))
  System.closeFile(file)

  local i,j = string.find(ux_version_text, "gamelist=%d+%.%d+")
  ux_list_version = string.sub(ux_version_text, i, j)
  local ux_list_version_num = GetNumber(ux_list_version)

  i,j = string.find(ux_version_text, "app=%d+%.%d+")
  ux_app_version = string.sub(ux_version_text, i, j)
  local ux_app_version_num = GetNumber(ux_app_version)

  list_v_num = ux_list_version_num
  app_v_num = ux_app_version_num

  if list_version_num > ux_list_version_num or app_version_num > ux_app_version_num then
    System.deleteFile("ux0:data/VitaGrafix/versions.txt")
    file = System.openFile("ux0:data/VitaGrafix/versions.txt", FCREATE)
    System.writeFile(file, version_text, string.len(version_text))
    System.closeFile(file)

    file = System.openFile("app0:/gamelist.txt", FREAD)
    System.seekFile(file, 0, SET)
    local gamelisttext = System.readFile(file, System.sizeFile(file))
    System.closeFile(file)

    file = System.openFile("ux0:data/VitaGrafix/gamelist.txt", FCREATE)
    System.writeFile(file, gamelisttext, string.len(gamelisttext))
    System.closeFile(file)

    list_v_num = list_version_num
    app_v_num = app_version_num

  end



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
    elseif string.match( game.id[i],  "PCSH") or string.match( game.id[i],  "PCSD") or string.match( game.id[i],  "VCAS") or string.match( game.id[i],  "VLAS") then
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

-- Get Installed games on a system
function GetInstalledGames()
  local installedGameDirs = System.listDirectory("ur0:/appmeta")
  for i = 1, #installedGameDirs, 1 do
    table.insert(installedGamesList, installedGameDirs[i].name)
  end
end

function CheckIfGameInstalled(game)
 
  for i = 1, #game.id, 1 do
    for j = 1, #installedGamesList, 1 do
      if game.id[i] == installedGamesList[j] then
        return true
      end
    end
  end

  return false
end

function FindGameInDirection(dir)
  if display_installed then
    if dir == -1 then
      for i = gameCounter-1, 1, -1 do
        local isInstalled = CheckIfGameInstalled(games[i])
        if isInstalled then
          return i
        end
      end
      return 0
    else
      for i = gameCounter+1, #games, 1 do
        local isInstalled = CheckIfGameInstalled(games[i])
        if isInstalled then
          return i
        end
      end
      return 0
    end
  else
    if dir == -1 then
      return gameCounter - 1
    else
      if gameCounter < #games then
        return gameCounter + 1
      else
        return 0
      end
    end
  end
end

function GetGameBlock(startPoint)
  local name = ""
  local gameBlock = ""
  
  if startPoint == nil or startPoint >= string.len(game_list) then
    return false
  end
  
  local i, j = string.find(game_list, "#(.-)\n\n", startPoint)
  local k, l = string.find(game_list, "#(.-)%[", startPoint)

  name = string.sub(game_list, k+2, l-2)
  name = string.gsub(name, "\n", "")

  if i == nil then
    i = string.len(game_list) + 1
  end
  
  gameBlock = string.sub(game_list, startPoint, j)
  return gameBlock, j, name
end

function NewGameParameters(textBlock)
  local ids = {}
  local fb = "false"
  local ib = "false"
  local fps = "false"
  local msaa = "false"
  local pfileUse = false
  local pfileName = ""

  if textBlock ~= false then
    local i, j = string.find(textBlock, "%[P(.-),", 0)
    local counter = 1
    while i ~= nil do
      ids[counter] = string.sub(textBlock, i+1, j-1)
      
      counter = counter + 1

      i, j = string.find(textBlock, "%[P(.-),", j)
    end

    i, j = string.find(textBlock, "@IB", 0)
    if i ~= null then
      ib = "OFF"
    end

    i, j = string.find(textBlock, "@FB", 0)
    if i ~= null then
      fb = "OFF"
    end

    i, j = string.find(textBlock, "@FPS", 0)
    if i ~= null then
      fps = "OFF"
    end
    
    i, j = string.find(textBlock, "@MSAA", 0)
    if i ~= null then
      msaa = "OFF"
    end
    
    i, j = string.find(textBlock, "%!USE%((.-)%)", 0)
    if i ~= null then
      pfileUse = true
      i, j = string.find(textBlock, "%((.-)%)", i)
      local patchFileName = string.sub(textBlock, i+1, j-1)
      pfileName = patchFileName
      if System.doesFileExist("ux0:data/VitaGrafix/patch/" .. patchFileName .. ".txt") then
 
      
        local patch_file = System.openFile("ux0:data/VitaGrafix/patch/" .. patchFileName .. ".txt", FREAD)
        System.seekFile(patch_file , 0, SET)
        local patch_list = System.readFile(patch_file , System.sizeFile(patch_file ))
        System.closeFile(patch_file )
        
        i, j = string.find(patch_list, "@IB", 0)
        if i ~= null then
          ib = "OFF"
        end

        i, j = string.find(patch_list, "@FB", 0)
        if i ~= null then
          fb = "OFF"
        end

        i, j = string.find(patch_list, "@FPS", 0)
        if i ~= null then
          fps = "OFF"
        end
        
        i, j = string.find(patch_list, "@MSAA", 0)
        if i ~= null then
          msaa = "OFF"
        end
        
      end
    end
    
  end
  return ids, fb, ib, fps, msaa, pfileUse, pfileName
end

-- Add games to the game list
function CreateGameList()
  System.createDirectory("ux0:data/VitaGrafix")
  if not System.doesFileExist("ux0:data/VitaGrafix/patchlist.txt") then
    local original_file = System.openFile("app0:/patchlist.txt", FREAD)
    System.seekFile(original_file, 0, SET)
    game_list = System.readFile(original_file, System.sizeFile(original_file))
    System.closeFile(original_file)
    local new_file = System.openFile("ux0:data/VitaGrafix/patchlist.txt", FCREATE)
    System.writeFile(new_file, game_list, string.len(game_list))
    System.closeFile(new_file)

  end
  local file = System.openFile("ux0:data/VitaGrafix/patchlist.txt", FREAD)
  System.seekFile(file, 0, SET)
  game_list = System.readFile(file, System.sizeFile(file))
  
  game_list = string.gsub(game_list, "\r", "")

  local gameBlock, point, name = GetGameBlock(ExcludeHeader())
  -- Read First Game Parameters
  while gameBlock ~= false do -- While there is a game, keep adding games to the list
    local ids, fb, ib, fps, msaa, pfileUse, pfileName = NewGameParameters(gameBlock)
    games[gameCounter] = Game:New(name, ids, fb, ib, fps, msaa, pfileUse, pfileName, 0) -- Needs extra 0 or function bugs out and parameters go to the wrong variables
    gameCounter = gameCounter + 1
    gameBlock, point, name = GetGameBlock(point)
  end
  System.closeFile(file)
  gameCounter = 0 -- Set Game counter to 0 as it's now going to be used as our game selector on the menu
end

function VerifyGameExistence()
  local markedToRemove = {}
  local skipCounter = 1
  local lastGame = 0
  for i = 1, #games, 1 do
    
    if i ~= lastGame + skipCounter then
      goto loopEnd
    end
    
    skipCounter = 1
    for j = i + 1, #games, 1 do
      if games[i].name == games[j].name then
        
          if games[j].ib ~= "false" then
            games[i].ib = games[j].ib
          end
          
          if games[j].fb ~= "false" then
            games[i].fb = games[j].fb
          end
          
          if games[j].fps ~= "false" then
            games[i].fps = games[j].fps
          end
          
          if games[j].ib ~= "false" then
            games[i].msaa = games[j].msaa
          end
        
        for k = 1, #games[j].id, 1 do
          table.insert(games[i].id, games[j].id[k])
        end
        
        table.insert(markedToRemove, j)
        skipCounter = skipCounter + 1
      
      end
      
    end
    lastGame = i
    ::loopEnd::
  end
  
  
  for i = #markedToRemove, 1, -1 do
    table.remove( games, markedToRemove[i])
  end

end

function ExcludeHeader()
  
  local newStartPoint = 0
  local i, j = string.find(game_list, "#(.-)\n\n", j)
  
  newStartPoint = j
  return newStartPoint
end

function SortGames()
  local sort_func = function( a,b ) return a.name < b.name end
  table.sort( games, sort_func )
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

            k,l = string.find(pre_text, "MSAA=")
            if k ~= nil then
              local msaa = ""
              delim = ","
              while l < string.len( pre_text ) and delim ~= "\n" do
                msaa = msaa .. string.sub(pre_text, l+1, l+1)
                l = l + 1
                delim = string.sub(pre_text, l+1, l+1)
              end
              games[i].msaa = msaa
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
  elseif string.match( str, "MSAA" ) then
    return game.default_msaa
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

    if game.msaa ~= "false" then
      config_text = config_text .. "\nMSAA=" .. game.msaa
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

  --Graphics.debugPrint(300, 10, "List: " .. tostring(list_v_num), Color.new(255,255,255))
  Graphics.debugPrint(400, 10, "App: 3.0", Color.new(255,255,255))

 
  if gameCounter == 0 then  -- If on VitaGrafix settings
    Graphics.debugPrint(350, 80, "VitaGrafix Settings", Color.new(255,255,255))

   

    local game1Name = games[#games].name
    local game2Name = games[1].name
    leftGameId = #games
    rightGameId = 1

    if display_installed == true then

      local foundGame1 = false

      for i = #games, 1, -1 do
        local isInstalled = CheckIfGameInstalled(games[i])
        if isInstalled == true then
          game1Name = games[i].name
          leftGameId = i
          foundGame1 = true
          break
        end
      end

      local foundGame2 = false

      for i = 1, #games, 1 do
        local isInstalled = CheckIfGameInstalled(games[i])
        if isInstalled == true then
          game2Name = games[i].name
          rightGameId = i
          foundGame2 = true
          break
        end
      end

      if not foundGame1 then
        game1Name = "VitaGrafix Settings"
        leftGameId = 0
      end

      if not foundGame2 then
        game2Name = "VitaGrafix Settings"
        rightGameId = 0
      end

    end

    if string.len(game1Name) < 25 then
      max_len = string.len(game1Name)
    end

    Graphics.debugPrint(5, 80, string.sub(game1Name, 0, max_len), Color.new(150,150,150))

    max_len = 25
    if string.len(game2Name) < 25 then
      max_len = string.len(game2Name)
    end

    Graphics.debugPrint(650, 80, string.sub(game2Name, 0, max_len), Color.new(150,150,150))

    Graphics.debugPrint(5, 150, "Enabled", Color.new(255,255,255))
    Graphics.debugPrint(5, 180, "OSD", Color.new(255,255,255))
    Graphics.debugPrint(5, 210, "Only show installed games", Color.new(255,255,255))

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

    if display_installed == true then
      Graphics.debugPrint(280, 210, "X", Color.new(255,255,255))
    else
      Graphics.debugPrint(280, 210, "", Color.new(255,255,255))
    end

    objectNum = 3

    Graphics.debugPrint(5, 150 + 30 * objectNum, "Save Config", Color.new(255,255,255))
    save_button = objectNum + 1

    available_buttons = 4

  else -- If on any game
    
    
    textCharMax = string.len(games[gameCounter].name)

    Graphics.debugPrint(textX, 80, games[gameCounter].name, Color.new(255,255,255))

    -- Black Rects to hide text while scrolling
    Graphics.fillRect(0, 350, 70, 110, Color.new(0,0,0))
    Graphics.fillRect(600, 960, 70, 110, Color.new(0,0,0))

    if leftGameId == 0 then
      Graphics.debugPrint(5, 80, "VitaGrafix Settings", Color.new(150,150,150))
    else
      max_len = 25
      if string.len(games[leftGameId].name) < 25 then
        max_len = string.len(games[leftGameId].name)
      end
      Graphics.debugPrint(5, 80, string.sub(games[leftGameId].name, 0, max_len), Color.new(150,150,150))
    end
    
    if rightGameId == 0 then
      Graphics.debugPrint(650, 80, "VitaGrafix Settings", Color.new(150,150,150))
    else
      max_len = 25
      if string.len(games[rightGameId].name) < 25 then
        max_len = string.len(games[rightGameId].name)
      end
      Graphics.debugPrint(650, 80, string.sub(games[rightGameId].name, 0, max_len), Color.new(150,150,150))
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
      Graphics.debugPrint(550, 150 + 30 * objectNum, "(Default: " .. games[gameCounter].default_fb .. ")", Color.new(255,255,255)) 
      objectNum = objectNum + 1
      fb_button = objectNum
    end

    if games[gameCounter].ib ~= "false" then
      Graphics.debugPrint(5, 150 + 30 * objectNum, "Internal Resolution", Color.new(255,255,255))

      if string.len(games[gameCounter].ib) >= 20 then
        Graphics.debugPrint(250, 150 + 30 * objectNum, "Multiple Resolutions", Color.new(255,255,255))
      else
        Graphics.debugPrint(250, 150 + 30 * objectNum, games[gameCounter].ib, Color.new(255,255,255))
      end
      Graphics.debugPrint(550, 150 + 30 * objectNum, "(Default: " .. games[gameCounter].default_ib .. ")", Color.new(255,255,255))
      objectNum = objectNum + 1
      ib_button = objectNum
    end

    if games[gameCounter].fps ~= "false" then
      Graphics.debugPrint(5, 150 + 30 * objectNum, "FPS Cap", Color.new(255,255,255))
      Graphics.debugPrint(250, 150 + 30 * objectNum, games[gameCounter].fps, Color.new(255,255,255))
      Graphics.debugPrint(550, 150 + 30 * objectNum, "(Default: " .. games[gameCounter].default_fps .. ")", Color.new(255,255,255))
      objectNum = objectNum + 1
      fps_button = objectNum
    end

    if games[gameCounter].msaa ~= "false" then
      Graphics.debugPrint(5, 150 + 30 * objectNum, "MSAA", Color.new(255,255,255))
      Graphics.debugPrint(250, 150 + 30 * objectNum, games[gameCounter].msaa, Color.new(255,255,255))
      Graphics.debugPrint(550, 150 + 30 * objectNum, "(Default: " .. games[gameCounter].default_msaa .. ")", Color.new(255,255,255))
      objectNum = objectNum + 1
      msaa_button = objectNum
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
    if(games[gameCounter].asia) then
      region_text = region_text .. "[Asia] "
    end
    Graphics.debugPrint(5, 360, region_text, Color.new(255,255,255))


    if games[gameCounter].msaa == "false" and games[gameCounter].fps == "false" and games[gameCounter].ib == "false" and games[gameCounter].fb == "false" then
      if games[gameCounter].usesPatchfile == true then
        Graphics.debugPrint(5, 420, "This game requires the specific patch file " .. games[gameCounter].patchFile .. ".txt", Color.new(255,255,255))
        Graphics.debugPrint(5, 450, "Installed at ux0:data/VitaGrafix/patch/", Color.new(255,255,255))
      end
    end

    if selected_button > 2 and selected_button < available_buttons then
      Graphics.debugPrint(600, 10, "Press Triangle for default setting", Color.new(255,255,255))
    end
  end

  

end

-- Function called when X was pressed
function CrossPressed()
  if selected_button == save_button then -- Save button, saves ENTIRE CONFIG (not game specific changes)
    WriteToFile()
    WriteAppConfig()
    EndDraw()
    BeginDraw()
    Graphics.debugPrint(350, 252, "Configuration Saved!", Color.new(255,255,255))
    EndDraw()

    System.wait(1000000)
  elseif selected_button == 1 then -- Button 1 is the enabled option
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
    Keyboard.show("0 < X <= 960 and 0 < Y <= 544 or OFF", games[gameCounter].ib, 255, TYPE_DEFAULT, MODE_TEXT)
  elseif selected_button == 3 then -- Button 3 is the Display Installed button
    if gameCounter == 0 then
      display_installed = not display_installed
    end
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
  elseif selected_button == msaa_button then
    games[gameCounter].msaa = games[gameCounter].default_msaa
  end
end

-- Function called when up or down are pressed, dir = -1 is left and dir = 1 is right
function DirectionPressed(dir)
  if selected_button == 0 then -- Button 0 is the game list
    if dir == -1 then 
      local temp = gameCounter
      gameCounter = leftGameId
      rightGameId = temp
      leftGameId = FindGameInDirection(dir)
      SetScrollVars()
    else
      local temp = gameCounter
      gameCounter = rightGameId
      leftGameId = temp
      rightGameId = FindGameInDirection(dir)
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
        games[gameCounter].fps = "20"
      else
        games[gameCounter].fps = "60"
      end 
    elseif string.match(games[gameCounter].fps, "20") then
      if dir == -1 then
        games[gameCounter].fps = "OFF"
      else
        games[gameCounter].fps = "30"
      end 
    elseif string.match(games[gameCounter].fps, "OFF") then
      if dir == -1 then
        games[gameCounter].fps = "60"
      else
        games[gameCounter].fps = "20"
      end 
    end

  elseif selected_button == msaa_button then -- Change MSAA

    if string.match(games[gameCounter].msaa, "4") then
      if dir == -1 then
        games[gameCounter].msaa = "2"
      else
        games[gameCounter].msaa = "OFF"
      end 
    elseif string.match(games[gameCounter].msaa, "2") then
      if dir == -1 then
        games[gameCounter].msaa = "OFF"
      else
        games[gameCounter].msaa = "4"
      end 
    elseif string.match(games[gameCounter].msaa, "OFF") then
      if dir == -1 then
        games[gameCounter].msaa = "4"
      else
        games[gameCounter].msaa = "2"
      end 
    end
  end
end

-- Initialization function
function Start()
  
  --GetLocalVersion()
  CreateGameList()
  VerifyGameExistence()
  SortGames()
  GetInstalledGames()
  FindCurrentSettings()
  GetRegions()
  WriteToFile()
  ReadAppConfig()
  if #games == 0 then
    finished_successfuly = false
  end
end

------------------------------------------------------------------------------------------------- Code Execution ----------------------------------------------------------------------------

Start()

-- Update Loop
while true do
  
  -- Run the update at 60 FPS
  if (Timer.getTime(timerObj) >= 16.7) then
    
    Timer.reset(timerObj)

    if (checkForUpgrade) then
      GetVersion()
      checkForUpgrade = false
    end

    BeginDraw()
    if finished_successfuly then

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
            local temp = gameCounter
            gameCounter = leftGameId
            rightGameId = temp
            leftGameId = FindGameInDirection(-1)
            SetScrollVars()
          end

          if Controls.check(pad, SCE_CTRL_RTRIGGER) then
            local temp = gameCounter
            gameCounter = rightGameId
            leftGameId = temp
            rightGameId = FindGameInDirection(1)
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

    else
      Graphics.debugPrint(300, 200, "Patchlist.txt not correctly set up", Color.new(255,255,255))
      Graphics.debugPrint(180, 230, "Download it from https://github.com/Electry/VitaGrafixPatchlist", Color.new(255,255,255))
      Graphics.debugPrint(300, 260, "and follow instructions to install", Color.new(255,255,255))
    end

    previousPad = pad
    EndDraw()
  end

 
end