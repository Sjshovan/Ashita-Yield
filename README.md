**Author:** [Sjshovan (LoTekkie)](https://github.com/LoTekkie)  
**Version:** v1.0.3


# Yield

> An Ashita v3 addon that allows you to track and edit gathering metrics within a simple GUI in Final Fantasy 11 Online.

<img src="https://i.postimg.cc/rsWfXXN8/yield-1-0-1.png..." data-canonical-src="https://i.postimg.cc/rsWfXXN8/yield-1-0-1.png" width="175" height="350" />
<img src="https://i.postimg.cc/3RkL1Dy0/yield-1-0-2.png..." data-canonical-src="https://i.postimg.cc/3RkL1Dy0/yield-1-0-2.png" width="400" height="350" />
<img src="https://i.postimg.cc/FKWW0xKQ/yield-1-0-3.png..." data-canonical-src="https://i.postimg.cc/FKWW0xKQ/yield-1-0-3.png" width="400" height="350" />
<img src="https://i.postimg.cc/bJ4mBNbC/yield-1-0-4.png..." data-canonical-src="https://i.postimg.cc/bJ4mBNbC/yield-1-0-4.png" width="400" height="350" />
<img src="https://i.postimg.cc/pVnGnzbg/yield-1-0-5.png..." data-canonical-src="https://i.postimg.cc/pVnGnzbg/yield-1-0-5.png" width="400" height="350" />
<img src="https://i.postimg.cc/Fs5Pbzh1/yield-1-0-6.png..." data-canonical-src="https://i.postimg.cc/Fs5Pbzh1/yield-1-0-6.png" width="400" height="350" />  

### Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Upgrading](#upgrading)
- [Aliases](#aliases)
- [Usage](#usage)
- [Commands](#commands)
- [Support](#support)
- [Change Log](#change-log)
- [Known Issues](#known-issues)
- [TODOs](#todos)
- [License](#license)

___
### Prerequisites
1. [Final Fantasy 11 Online](http://www.playonline.com/ff11us/index.shtml)
2. [Ashita v3](https://www.ashitaxi.com/)

___
### Installation

**Ashita:**   
1. Navigate to the `Addons` section on the left.
2. Locate the `Yield` addon.
3. Click the flashing download button near the upper-right corner.

**Manual:**
1. Navigate to <https://github.com/LoTekkie/Ashita-Yield>.
2. Click on `Releases`. 
3. Click on the `Source code (zip)` link within the latest release to download.
4. Extract the zipped folder to `Ashita_v3/addons/`.
5. Rename the folder to remove the version tag (`-v1.0.3`). The folder should be named `Yield`.

**Autoloading:**   

By default you will need to manually load this addon each time you restart the game.
To autoload Yield so that it is always ready for use upon entering the game, follow these steps:

1. Navigate to the `Ashita_v3/scripts/` directory.
2. Open the `Default.txt` file.
3. Locate the `Load Common Addons` section.
4. add the following line: `/addon load yield`.

___
### Upgrading

If you have a previous installation of Yield and you are installing manually, follow the steps below to ensure you don't encounter any issues.   

1. Exit out of Final Fantasy XI.
2. Install latest version of Yield.
3. Delete your /settings folder.
4. Load Finaly Fantasy XI.
5. Load Yield.

___
### Aliases
The following aliases are available to Yield commands:    

**yield:** yld  
**unload:** u  
**reload:** r  
**find:** f  
**about:** a  
**help:** h  
 
 ___
### Usage

Manually load the addon by using the following command:
    
    /addon load yield  
    
___    
### Commands

**help**

Displays available Yield commands. Below are the equivalent ways of calling the command:

    /yield help
    /yld help
    /yield h
    /yld h
    
**unload**

Unloads the Yield addon. Below are the equivalent ways of calling the command:
    
    /yield unload
    /yld unload
    /yield u
    /yld u
    
**reload**

Reloads the Yield addon. Below are the equivalent ways of calling the command:
    
    /yield reload
    /yld reload
    /yield r
    /yld r

**find**

Positions the Yield window to the top left corner of your screen. Below are the equivalent ways of calling the command:
    
    /yield find
    /yld find
    /yield f
    /yld f


**about**

Displays information about the Yield addon. Below are the equivalent ways of calling the command:
    
    /yield about
    /yld about
    /yield a
    /yld a
    
___
### Support
**Having Issues with this addon?**
* Please let me know here: [https://github.com/LoTekkie/Ashita-Yield/issues/new](https://github.com/LoTekkie/Ashita-Yield/issues/new).
  
**Have something to say?**
* Send me some feedback here: <Sjshovan@Gmail.com>

**Want to stay in the loop with my work?**
* You can follow me at: <https://twitter.com/Sjshovan>

**Wanna toss a coin to your modder?**
* You can do so here: <https://www.Paypal.me/Sjshovan>  
**OR**
* For Gil donations: I play on Wings private server! (<https://www.wingsxi.com/wings/>) My in-game name is LoTekkie.

___
### Change Log
**v1.0.3** - 08/27/2021 (First Ashita Release)
- Removed escape button option for confirm modals.

**v1.0.2** - 08/26/2021
- Fixed typo in Platinum Ore yield.
- Fixed issue with sounds occasionally not loading correctly.

**v1.0.1** - 7/21/2021
- Fixed auto-load issue.
- Fixed issue with report management when no character is available.
- Added first load behavior.

**v1.0.0** - 7/13/2021 (First Official Release)
- Rewrote Clamming logic.
- Added bucket pz value to visible Clamming metrics.
- Added Fishing skill-up alert.
- Added Clamming bucket break alert.
- Changed clamming kit metric value to be more readable.
- Added multiple character support for reports.
- Fixed issue where Yield would crash if gathering type was changed while zoning.
- Fixed report reading issues.
- Added saved window position.
- Added new find text command.
- Updated Q's and A's within the Help window.
- Added documentation strings to all functions/methods.
- Updated gathering logic.
- Added missing Clamming yields.
- Updated baseprices library.
- Fixed digging moon percentage tooltip.
- Fixed errors when changing gathering state while settings are open.
- Added value change colors to plots.
- Added value change colors to progress bar.
- Fixed issue where total yields metric was not adjusted when using the yield list buttons.
- Updated Feedback section in Settings.
- Fixed issue where yields were not readonly when NPC price mode was activated.
- Updated UI in Set Prices Settings.
- Updated UI in Set Colors Settings.
- Updated main window to position center with fresh settings.
- Updated sub windows to position center when becoming visible.
- Updated title.

**v0.9.5b** - 7/8/2021
- Fixed stack size data across many yields.
- Changed Settings window type away from modal.
- Added feature to disable price inputs when using NPC prices.
- Added Reports feature and Reports settings.
- Updated About in Settings.
- Added Help window.

**v0.9.4b** - 7/6/2021
- Adjusted volume of UT audio files.
- Fixed issue with tab targeting focusing value input.
- Fixed error in chat-log when zoning.
- Fixed issue with fishing recording catches for others.
- Fixed name error with Copper Ring while fishing.
- Added Bomb Arm yield to mining.
- Fixed incorrect values for tools and inventory metrics when zoning.
- Updated about in settings.

**v0.9.3b** - 7/3/2021
- Added fishing.
- Added digging.
- Added feedback section in settings.
- Bug fixes.
- Updated UI.  

**v0.9.2b** - 7/2/2021  
- Added yield sound alerts.
- Added target value sound alert.
- Added set all options to colors and alerts settings.
- Adjusted price settings UI.
- Added option to enable/disable sound alerts.
- Added rounding to all UI elements.
- Bug fixes.
- Updated about section.

**v0.9.1b** - 7/1/2021   
- Revamped price settings.
- Added yield list buttons.
- Added NPC base price option.
- Added logging data.
- Added excavating data.
- Added clamming data.
- Added image buttons option.
- Added inactivity tracker.
- Updated addon title.
- Bug fixes.
- UI changes.

**v0.9.0b** - 6/28/2021  
- Rewrote state management system.
- Updated UI layout and colors.
- Added new metrics.
- Added harvesting data.
- Added ability to resize window.
- Added ability to change yield colors.
- Added new settings options.
- Added cycle options for yield and plot labels.
- Added timer controls.
- Added tooltips.
- Added input for estimated value.
- Added fishing and digging gathering types.
- Added stack prices option.
- Updated about section in settings.
- Added help button.
- Add ability to exit modals through clicks/escape button.

**v0.9.0a** - 6/19/2021  
- Initial upload.
___
### Known Issues

- **Issue:** Game window resizing causes the cursor position to change making GUI interaction difficult.
- **Issue:** Yield window size changes causes fonts to scale strangely.

___    
### TODOs
- **TODO:** Cleanup code, re-write some areas to improve performance/readability.
___

### License

Copyright © 2021, [Sjshovan (LoTekkie)](https://github.com/LoTekkie).
Released under the [BSD License](LICENSE).

***
