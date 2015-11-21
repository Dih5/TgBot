# TgBot

[![release v0.1.0](http://img.shields.io/badge/release-v0.1.0-red.svg)](https://github.com/dih5/TgBot/releases/latest)
[![Semantic Versioning](https://img.shields.io/badge/SemVer-2.0.0-brightgreen.svg)](http://semver.org/spec/v2.0.0.html)
[![license MIT](https://img.shields.io/badge/license-MIT%20Licencse-blue.svg)](https://github.com/dih5/TgBot/blob/master/LICENSE.txt)
[![Mathematica 10](https://img.shields.io/badge/Mathematica-10-brightgreen.svg)](#compatibility)


Package to implement bots using the Telegram API.


* [Usage example](#usage-example)
* [Installation](#installation)
    * [Automatic installation](#automatic-installation)
    * [Manual installation](#manual-installation)
    * [No installation](#no-installation)
* [Documentation](#documentation)
* [Compatibility](#compatibility)
* [Bugs and requests](#bugs-and-requests)
* [Contributing](#contributing)
* [License](#license)
* [Versioning](#versioning)


## Usage example

Check the following example:

![alt tag](https://raw.github.com/dih5/TgBot/master/demo.png)

This bot is done using the example notebook in this project.
Check out that notebook to see how the package is used.

## Installation


### Automatic installation

To install TgBot package evaluate:
```Mathematica
Get["https://raw.githubusercontent.com/dih5/TgBot/master/BootstrapInstall.m"]
```

This method uses [MathematicaBootstrapInstaller](https://github.com/jkuczm/MathematicaBootstrapInstaller) and will also install
[ProjectInstaller](https://github.com/lshifr/ProjectInstaller) package if you don't have it already installed.

To load TgBot package evaluate: ``Needs["TgBot`"]``.


### Manual installation

1. Download latest released
   [TgBot.zip](https://github.com/dih5/TgBot/releases/download/v0.1.0/TgBot.zip)
   file.

2. Extract downloaded `TgBot.zip` to any directory which is on the Mathematica `$Path`,
   e.g. to install for the current user `FileNameJoin[{$UserBaseDirectory,"Applications"}]`,
   for all users `FileNameJoin[{$BaseDirectory,"Applications"}]`.

3. To load the package evaluate: ``Needs["TgBot`"]``.


### No installation

To use package directly from the Web, without installation, evaluate:
```Mathematica
Get["https://raw.githubusercontent.com/dih5/TgBot/master/TgBot/TgBot.m"]
```

Note that this method loads the development version.
In this early stage of development the API should be considered unstable, so use at your own risk.


## Documentation

The API provided by the package is only documented with usage messages at the moment.
Check the first lines of 
As long as version < 1.0.0 documentation will *not* be integrated in the Mathematica Documentation Center.




## Compatibility

The package is being build with Mathematica version 10.* on Windows|Linux.
It will *not work for earlier versions* as it uses some functions which are 10.0+.
Partial support might be added for earlier versions in the future.



## Bugs and requests

If you find any bugs or have a feature request you may create an
[issue on GitHub](https://github.com/dih5/TgBot/issues).

If you are building a bot with this package I'd be glad to hear what you need. I encourage you to ask for it! :)



## Contributing

Feel free to fork and send pull requests, all contributions are welcome.



## License

This package is released under
[The MIT License](https://github.com/dih5/TgBot/master/LICENSE).



## Versioning

Releases of this package will be numbered using
[Semantic Versioning guidelines](http://semver.org/).
Note that while version < 1.0.0 the API is not considered stable. Expect changes.