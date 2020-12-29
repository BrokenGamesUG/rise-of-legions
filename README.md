# Rise of Legions
Rise of Legions is a hybrid of MOBA, tower defense and deckbuilding - with fast-paced, easy-to-pickup tug-of-war strategy. Play solo or bring a friend for co-op or 2v2, collect cards, build your deck and crush your enemies.

![Teaser Image](https://steamcdn-a.akamaihd.net/steam/apps/748940/ss_bc270313840c4e8567b2c69721f0d9155c0e7013.1920x1080.jpg?t=1602405461)

## Why is this game open source?
As we are passionated programmers we know that you are often curious about how something has been made. A lot of software looks like it is something you could never code, but everyone is cooking with water, but some only have a lot more cooks ;) We want everyone to be able to explore our code base how things are made and maybe find something interesting or inspiration that you only need passion to also deal with big projects. As we are still running Rise of Legions on Steam as a real product, we of course ask for a responsible use of everything in this repository. Moreover we only reveal our client and game server code. The master server code and supporting stuff will remain closed source as long we can keep the game live to everyone to enjoy :)

## How to use
Clone the repository and open the file BaseConflictGroup.groupproj in Delphi (we used Delphi 10.1 Berlin, other versions are not tested). Unpack the Music.bank.zip in Sound/Banks (too big for GitHub). Compile the game server and start it. Compile the client and start it. The client should automatically connect to the game server and a sandbox game should be running. The [engine](https://github.com/BrokenGamesUG/delphi3d-engine) was written by ourselves and is publicy available on Github too. Have a look at it for more hints and information.

## What is Base Conflict
Base Conflict is the project name of Rise of Legions, we initially started with. Later on we decided that it did not fit the theme of the game well as it was too military and looked for another name. A half year later we found it, naming can be hard :)

## License
The code base of Rise of Legions except the engine is licensed with:
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

The engine and its license and dependencies can be found on Github too: https://github.com/BrokenGamesUG/delphi3d-engine

All other files (graphics, soundseffects, etc.) are licensed with:
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
