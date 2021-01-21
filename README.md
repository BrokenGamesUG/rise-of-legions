# Rise of Legions
Rise of Legions is a hybrid of MOBA, tower defense and deckbuilding - with fast-paced, easy-to-pickup tug-of-war strategy. Play solo or bring a friend for co-op or 2v2, collect cards, build your deck and crush your enemies. It can be played on [Steam](https://store.steampowered.com/app/748940/Rise_of_Legions/) for free.

![Teaser Image](https://steamcdn-a.akamaihd.net/steam/apps/748940/ss_bc270313840c4e8567b2c69721f0d9155c0e7013.1920x1080.jpg?t=1602405461)

## Why is this game open source?
As we are passionated programmers we know that you are often curious about how something has been made. A lot of software looks like it is something you could never code, but everyone is cooking with water, but some only have a lot more cooks ;) We want everyone to be able to explore our code base how things are made and maybe find something interesting or inspiration that you only need passion to also deal with big projects. As we are still running Rise of Legions on Steam as a real product, we of course ask for a responsible use of everything in this repository. Moreover we only reveal our client and game server code. The master server code and supporting stuff will remain closed source as long we can keep the game live to everyone to enjoy :)

## How to use?

* Clone the repository and open the file BaseConflictGroup.groupproj in Delphi (we used Delphi 10.1 Berlin, other versions are not tested, but it should run on 10.4 we heart)
* With 10.1: The built-in DirectX-Headers contains some bugs, which has been fixed by us. Ensure to include the directory FixedDX11Header in your project, so the fixed WinapiD3D11.pas is used. Additionally you need to copy the FMX-Source-Files (from Embarcadero\Studio\18.0\source\fmx) into that folder as well to compile them with the patched api headers. Apply the diff FMX.Canvas.D2D.diff to the respective file.
* With 10.4+: Delete the WinapiD3D11.pas from the FixedDX11Header directory, remove the line FMX.Canvas.D3D.TCustomCanvasD2D.LoadFontFromFile(Path); from Engine.GfxApi. There won't be custom fonts, but it should compile and work then.
* Unpack the Music.bank.zip in Sound/Banks (too big for GitHub)
* Compile the game server and start it
* Compile the client and start it. The client should automatically connect to the game server and a sandbox game should be running. 

The [engine](https://github.com/BrokenGamesUG/delphi3d-engine) was written by ourselves and is publicy available on Github too. Have a look at it for more hints and information.

## Fmod project

Thanks to Michael the whole Fmod project is Open-Source too, so interested audio enthusiast can have a look under the hood of the games sound handling. You find it on [GitLab](https://gitlab.com/michaelklier/rise-of-legions).

## Credits

The game was developed by [Broken Games](http://brokengames.de/).


Art by Sebastian Adomat https://www.artstation.com/art-o-mat

Model Animations by Jennifer Jason http://www.jenniferjason.de/

Sound Effects by Michael Klier www.michaelklier.studio

Music by Julian Colbus www.mediacracy-music.com

Publishing by Max Dohme http://www.crunchyleafgames.com/

Everything else by Martin Lange and Tobias Tenbusch


## Where does the name "Base Conflict" come from?
Base Conflict is the project name of Rise of Legions, we initially started with. Later on we decided that it did not fit the theme of the game well as it was too military and looked for another name. A half year later we found it, naming can be hard :)

## License
The code base of Rise of Legions except the engine is licensed with:
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

The engine and its license and dependencies can be found on Github too: https://github.com/BrokenGamesUG/delphi3d-engine

All other files (graphics, soundseffects, etc.) are licensed with:
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
