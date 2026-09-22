# Azeroth Compendium

Azeroth Compendium brings a searchable, encounter and reward journal.

## Features

*   Browse Classic dungeons and raids by instance and encounter.
*   Switch each dungeon and raid between boss and quest lists, including faction and quest level.
*   Select a quest to see every required predecessor in order; select a chain step to place a
    world-map waypoint at its Wowhead quest giver when coordinates are available.
*   View boss loot, drop chances, abilities, and 3D models.
*   Browse PvP honor rewards and battleground faction rewards.
*   Browse reputation rewards grouped by faction and standing.
*   Save items to an account-wide wishlist and jump back to their source.
*   Search instances, bosses, factions, and items.
*   Switch the compendium between the complete Forever data and the Classic Era data.
*   Filter loot to items usable by the current class.
*   Show or hide drop chances.
*   Open the compendium from a minimap button or slash command.
*   Resize the compendium with the grip in its bottom-right corner; its size is remembered.
*   Use localized interface text for all supported game languages.

## Usage

*   Left-click the minimap button to open the compendium.
*   Right-click the minimap button to open the settings.
*   Use `/azerothcompendium` or `/ac` to open the compendium.
*   Use `/azerothcompendium settings` or `/ac settings` to open the settings.
*   Right-click an item to add it to or remove it from the wishlist.
*   Open the Wishlist tab and left-click an item to jump to its category, instance, and boss.
*   Right-click an item in the Wishlist tab to remove it.
*   Use the **Flavor** dropdown above the left list to show either all Forever data or only Classic Era content.

The **Only my class** option is shared between the compendium and the settings window. Changing it in either place updates the other checkbox immediately.

## Data

The addon ships with a static database and does not record loot while playing.

*   Classic instance, encounter, loot, and ability data is based on the CMaNGOS Classic database.
*   Curated dungeon trash loot is based on AtlasLootClassic data.
*   Dungeon quest IDs, levels, factions, and fallback names are based on Wowhead Classic and Forever zone pages.
*   World of Warcraft: Forever additions are based on publicly available Forever data.
*   Item names, icons, faction names, standing labels, and instance names are localized by the game client whenever possible.

Forever content can change during development. New or changed encounters may therefore have incomplete loot or ability data until reliable information becomes available.

## Supported client

- World of Warcraft: Forever / Camelot
- Interface version: `16001`

## Installation

Place the `AzerothCompendium` folder in your World of Warcraft `Interface\AddOns` directory and restart the game.

## License

See [LICENSE](LICENSE).
