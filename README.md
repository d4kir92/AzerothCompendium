# Azeroth Compendium

Azeroth Compendium brings a searchable, encounter and reward journal.

## Features

*   Browse Classic dungeons and raids by instance and encounter.
*   View boss loot, drop chances, abilities, and 3D models.
*   Browse PvP honor rewards and battleground faction rewards.
*   Browse reputation rewards grouped by faction and standing.
*   Search instances, bosses, factions, and items.
*   Filter loot to items usable by the current class.
*   Show or hide drop chances.
*   Open the compendium from a minimap button or slash command.
*   Use localized interface text for all supported game languages.

## Usage

*   Left-click the minimap button to open the compendium.
*   Right-click the minimap button to open the settings.
*   Use `/azerothcompendium` or `/ac` to open the compendium.
*   Use `/azerothcompendium settings` or `/ac settings` to open the settings.

The **Only my class** option is shared between the compendium and the settings window. Changing it in either place updates the other checkbox immediately.

## Data

The addon ships with a static database and does not record loot while playing.

*   Classic instance, encounter, loot, and ability data is based on the CMaNGOS Classic database.
*   Curated dungeon trash loot is based on AtlasLootClassic data.
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
