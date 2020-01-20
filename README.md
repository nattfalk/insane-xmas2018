# iNSANE - X-mas 2018 Amiga intro

![iNSANE X-mas 2018](screenshot.png)

An Amiga OCS/ECS intro by iNSANE released for Christmas 2018. Written in Motorola 68000 assembly.

Also available on [pouet.net](https://www.pouet.net/prod.php?which=79639)

## Prerequisites

- Visual Studio Code
- Amiga Assembly extension for VS Code. [https://github.com/prb28/vscode-amiga-assembly](https://github.com/prb28/vscode-amiga-assembly)
- VASM/VLINK. Prebuilt binaries available at [https://github.com/prb28/vscode-amiga-assembly-binaries](https://github.com/prb28/vscode-amiga-assembly-binaries)

## Installing

```bash
> git clone https://github.com/nattfalk/insane-xmas2018.git
> cd insane-xmas2018
> git clone --single-branch --branch windows_x64 https://github.com/prb28/vscode-amiga-assembly-binaries.git bin\windows_x64
```

## Usage

Open folder in VS Code, build and then run (Ctrl+F5). Main code in src/xmas2018.s

## Credits

- Code by me (Prospect)
- Graphics by Premium, Corel and Vedder
- Music by Juice
- Also a big thumb up to Photon/Scoopex for the startup code

## License

[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org)

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
