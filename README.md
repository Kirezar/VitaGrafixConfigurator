# ![VitaGrafix Configurator](https://i.imgur.com/hIdE4yQ.png)
A GUI Configurator for the VitaGrafix plugin

[Download Here](https://github.com/Kirezar/VitaGrafixConfigurator/releases)

## Requirements

This app requires the instalation of [VitaGrafix by Electry](https://github.com/Electry/VitaGrafix)

The configurator is compatible with **VitaGrafix v2.3 pre-release**

## Usage

After opening the app, if you don't have a **config.txt** file on **ux0:/data/VitaGrafix** or it wasn't updated to the latest version, the app will do that for you.

You'll be greeted by a VitaGrafix Settings screen, which contains the override settings for Enabled and OSD

![Main Menu](https://i.imgur.com/B9W4YxB.png)

### Controls

* **Up and Down on the DPAD:** Move the selection up or down

* **Cross:**
  * If the selected button is the "Enable" or "OSD" then it will toggle them On or Off (If marked by an X then they are On, if empty then they are Off)
  * If the selected button is the "Internal Resolution" button, the app will open the Keyboard where you can type the intended Internal Resolution. This resolution can be anything with a width between 0 (exclusive) and 960 (inclusive), and a height between 0 (exclusive) and 544 (inclusive) and has to follow the format: WxH. The Internal Resolution mod can also be set to "OFF" by inputing that into the text field.
  * If the selected button is the Save Config button, it will save the entire config.

* **Left and Right on the DPAD:**
  * If the selection is on the game list, it will scroll through the games
  * If the selection is either on Framebuffer or FPS, it will scroll through the available modes for those options
  
 * **Triangle:** If the selection is on any of the fields that have a (Default:) text in front of them, it will set those fields to the default value. The default value is the VitaGrafix plugin default and not the game default.
 
 * **L and R:** Moves trough the list of games (same as Left and Right but without the need of selecting the game list)
 
 ![Game screen](https://i.imgur.com/Xxgx0Ws.png)
 
 ### Saving
 
 After you are done setting the options to your liking, just press the Save Config button
 
 ## Cautions
 
 Not every option available might be compatible with each game, please refer to the [compatibility table on the VitaGrafix github page](https://github.com/Electry/VitaGrafix#supported-games)
 
 ## Build

 If you want to build it from source yourself, you are free to do so, download https://github.com/Rinnegatamante/lpp-vita and follow the instructions on the readme file.
 
 ## Known Issues / Possible new features
 
 As of this version, you aren't able to save individual profiles for different supported regions, I didn't think it was needed, if it is, please request it
 
 Graphical interface is ugly, I have zero graphics skills

 ## Thanks to the following people

* [Electry](https://github.com/Electry) for the VitaGrafix plugin
* [Rinnegatamante](https://github.com/Rinnegatamante/) for lpp-vita
