# ElvUI QuestBar

## Description
ElvUI QuestBar is an addon for World of Warcraft 3.3.5 (Wrath of the Lich King) that integrates with ElvUI and ElvUI ExtraActionBars. It utilizes Action Bar 10 from the ExtraActionBars plugin to create a dedicated "QuestBar" for easy access to usable quest items. The addon automatically scans your bags for quest-related items that can be used (e.g., for quests or to start quests) and displays them as icons on the QuestBar.

## Features
- **Automatic Bag Scanning**: Scans all bags for usable quest items and populates the QuestBar with up to 12 icons.
- **Test Mode**: Includes a "Show Test Icons" option to display dummy icons for testing purposes without real items.
- **Dynamic Visibility**: The bar hides when there are no quest items or during vehicle UI.
- **ElvUI Integration**: Seamlessly integrates with ElvUI's action bar system, hiding Bar 10 in options when enabled.
- **Movable Anchor**: Allows toggling the bar's anchor for repositioning.
- **Combat Safe**: Updates are deferred during combat to avoid issues.

## Installation
1. Ensure you have ElvUI (version 7.23 or compatible) installed from [Ascension-Addons/ElvUI](https://github.com/Ascension-Addons/ElvUI).
2. Install ElvUI ExtraActionBars from [ElvUI-WotLK/ElvUI_ExtraActionBars](https://github.com/ElvUI-WotLK/ElvUI_ExtraActionBars).
3. Download the ElvUI_QuestBar addon files.
4. Place the `ElvUI_QuestBar` folder in your `World of Warcraft/Interface/AddOns/` directory.
5. Restart World of Warcraft or reload your UI with `/reload`.
6. Enable the addon in ElvUI options under the QuestBar section.

## Usage
- **Enabling the QuestBar**: Go to ElvUI options and enable QuestBar under the ActionBars section.
- **Test Icons**: Use the "Show Test Icons" button to display placeholder icons for testing.
- **Toggle Anchor**: Use the "Toggle Anchor" button to show/hide the movable anchor for repositioning the bar.
- **Automatic Updates**: The bar updates automatically when bags change, but only outside of combat.

## Dependencies
- ElvUI (required)
- ElvUI_ExtraActionBars (required)

## Configuration
Access options via ElvUI's configuration panel:
- **Enabled**: Toggle the QuestBar on/off.
- **Max Buttons**: Set the maximum number of buttons (default: 12).
- **Auto Scan**: Enable/disable automatic bag scanning.

## Troubleshooting
- **Addon not loading**: Ensure all dependencies are installed and up to date.
- **Errors on enable**: Check that ElvUI and ExtraActionBars are properly loaded. Try `/reload` if issues persist.
- **No icons showing**: Verify you have usable quest items in your bags. Use test mode to confirm the bar is working.

## Version
1.0

## Author
Elvi (Bronzebeard)

## License
This addon is provided as-is for use in World of Warcraft. Please refer to ElvUI's license for any additional terms.

## Support
For issues or suggestions, please check the GitHub repositories for ElvUI and related addons.
