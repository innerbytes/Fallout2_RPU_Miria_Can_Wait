## Miria Can Wait patch for the Fallout 2 Restoration Project Updated mod

When this patch is applied, Miria can be told to wait at her current location, just like other party NPCs (Sulik, Cassidy, etc.). The player can then return and ask her to rejoin the party.
This prevents Miria to be killed in hard battles. This patch does not extend any other functionality of Miria, only the above described one.

### How to apply:

1. This patch is tested with the latest RPU for the moment: `v2.4.34`, so please install first this version of the RPU, following all the installation instructions:
    - https://github.com/BGforgeNet/Fallout2_Restoration_Project?tab=readme-ov-file#installation 
    - https://github.com/BGforgeNet/Fallout2_Restoration_Project/releases/tag/v2.4.34
    - This patch is not guaranteed to work with other versions of RPU until tested, but it can.
2. This intallation instruction assumes that your Fallout 2 game with RPU is installed in `C:\Games\Fallout 2\` directory. Update the path accordingly if it differs.
3. Clone this github repository (for example into `c:\Projects\Fallout2_RPU_Miria_Can_Wait` directory).
4. Download `compile.exe` and `parser.dll` from sfall-team/sslc releases:
    - Can take this version, or later: https://github.com/sfall-team/sslc/releases/tag/2026-02-07-11-20-26
    - Place both files in the same folder (e.g. `C:\Tools\`).
5. Compile the patch using commands in PowerShell 7:
    -  `cd c:\Projects\Fallout2_RPU_Miria_Can_Wait\scripts_src\modoc`
    -  `C:\Tools\compile.exe -p -l -O2 -s -q -n mcmiria.ssl -o mcmiria.int`
6. Make a backup of your Fallout 2 `C:\Games\Fallout 2\data\` directory for the case something goes wrong.
7. Apply the patch to your Fallout 2 RPU installation, running those Powershell 7 commands:
   ```poweshell
     mkdir "C:\Games\Fallout 2\data\scripts" 2>nul
     mkdir "C:\Games\Fallout 2\data\text\english\dialog" 2>nul
     copy scripts_src\modoc\mcmiria.int "C:\Games\Fallout 2\data\scripts\mcmiria.int"
     copy data\text\english\dialog\mcmiria.msg "C:\Games\Fallout 2\data\text\english\dialog\mcmiria.msg"
   ```
8. Verify ddraw.ini
    - Open `C:\Games\Fallout 2\ddraw.ini` and confirm under [Misc]: `UseFileSystemOverride=1` (Should already be 1 in a standard RPU install)
9. Enable the Miria Can Wait feature:
    - Edit `C:\Games\Fallout 2\mods\rpu.ini` and add in the end: `miria_can_wait=1`
10. That's it. Now when you marry Miria and join you in your squad, she can be asked to wait, same as any other companion.

## Fallout 2 Restoration Project, updated <a href="#"><img align="right" src="extra/bin/fallout2_logo.png" width="35%" alt="Fallout 2 logo"/></a>

[![Build status](https://github.com/BGforgeNet/Fallout2_Restoration_Project/workflows/build/badge.svg)](https://github.com/BGforgeNet/Fallout2_Restoration_Project/actions?query=workflow%3Abuild)
[![Translation status](https://hive.bgforge.net/widgets/fallout/-/rp/svg-badge.svg)](https://hive.bgforge.net/projects/fallout/rp/)

[![Telegram](https://img.shields.io/badge/telegram-join%20%20%20%20%E2%9D%B1%E2%9D%B1%E2%9D%B1-darkorange?logo=telegram)](https://t.me/bgforge)
[![Discord](https://img.shields.io/discord/420268540700917760?logo=discord&label=discord&color=blue&logoColor=FEE75C)](https://discord.gg/4Yqfggm)
[![IRC](https://img.shields.io/badge/%23IRC-join%20%20%20%20%E2%9D%B1%E2%9D%B1%E2%9D%B1-darkorange)](https://bgforge.net/irc)

[**Download**](https://github.com/BGforgeNet/Fallout2_Restoration_Project/releases/latest)
| [**Installation**](#installation)
| [**Bug reports**](#bug-reports-feature-requests)
| [**Translations**](docs/translations.md)
| [**Additional mods**](#additional-mods)

**Restoration Project, updated** is based on [killap's Restoration Project](http://killap.net/) for Fallout 2.

### Installation

- RPU must be installed on vanilla game.
- RPU requires starting a new game after installation. (One exception is [updating](docs/update.md) from RP or a previous RPU version).

#### Windows

1. Download `rpu_v*.exe` from the [latest release](https://github.com/BGforgeNet/Fallout2_Restoration_Project/releases/latest) page.
1. Launch, point the installer to the game directory, choose language and options.
1. After installation, see `mods/upu.ini`, `mods/rpu.ini` for various settings that can be configured.
1. Check out [recommended](#recommended) mods to add on top.

#### Linux / MacOS

Follow the [instruction](docs/linux.md).

### Additional mods

#### Included

RPU includes the following mods:

- [Unofficial Patch](https://github.com/BGforgeNet/Fallout2_Unofficial_Patch)
- [High quality music](https://github.com/BGforgeNet/Fallout2-HQ-music)
- [Hero Appearance](https://github.com/BGforgeNet/Fallout2_Hero_Appearance)
- [NPC armor](https://github.com/BGforgeNet/Fallout2_NPC_Armor)
- [Party Orders](https://github.com/BGforgeNet/Fallout2_Party_Orders)
- [Cassidy talking head](https://github.com/BGforgeNet/Fallout2_Cassidy_Head)
- Enhanced worldmap
- [Extended Flamer animations](https://www.nma-fallout.com/threads/the-extended-flamer-attack-mod.192732/)
- Additional rifle and wakizashi animations
- Improved Mysterious Stranger
- High resolution patch

#### Recommended

For additional QoL options, check out:

- [Lossless music](https://github.com/BGforgeNet/Fallout2-HQ-music)
- [FO2tweaks](https://github.com/BGforgeNet/FO2tweaks)
- [Inventory Filter](https://github.com/rotators/InventoryFilter)

### Bug reports, feature requests

1. Go to [github issues](https://github.com/BGforgeNet/Fallout2_Restoration_Project/issues) or [forums](https://forums.bgforge.net/viewforum.php?f=39).
2. Open an issue/topic, describe the bug. Report each bug separately.
3. Attach a savegame and a screenshot.

### Additional info

- [Changelog](docs/changelog.md)
- [New content description](https://github.com/BGforgeNet/Fallout2_Restoration_Project/blob/master/docs/rp-new_content.txt) (spoilers)
- [Walkthrough](https://f2rp.bgforge.net/) (heavy spoilers)
- [Known issues](docs/known.md)
- [Reporting crashes](https://github.com/BGforgeNet/Fallout2_Unofficial_Patch/blob/master/docs/crash.md)
- [Credits](docs/credits.md)
