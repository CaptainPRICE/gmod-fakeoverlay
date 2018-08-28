# gmod-fakeoverlay
Prank your players with fake loading/disconnect screen. F-U-N! FUN ^ 2!

_When admins be 😈, others be 😆, and the victim be 😓._

I have written this in a very very short period of time (< 48 hours), so if you find any bugs (even a typo), please [submit it here](https://github.com/CaptainPRICE/gmod-fakeoverlay/issues/new)!


# Features
- Show fake overlay with custom message to any player
- Grained control (callbacks when victim receives/closes fake overlay on both serverside and clientside) / 3rd party addons support
- **???** (request new features via [issues tracking page](https://github.com/CaptainPRICE/gmod-fakeoverlay/issues))

# Getting Started
It is simple. Clone/Download a copy of the master branch into `./Steam/steamapps/common/GarrysMod/garrysmod/addons/gmod-fakeoverlay` folder (git will automatically create `gmod-fakeoverlay` folder for you; if you don't use git then create the folder yourself, how you name the addon folder does not really matter).
This is how the folder structure/hierarchy tree should look like:

```
addons
└───gmod-fakeoverlay
    ├───lua
    │   └───autorun
    │       └───client
    │       └───server
    └───materials
        └───fakeover
```

# Usage
By default, any admin on the server will be granted to run/execute the `sv_send_fakeover` console command. For more information, submit `help sv_send_fakeover` in Console.

# Documentation for 3rd party addons / Extensibility
If you are looking for documentation and/or code examples then navigate to the [wiki](https://github.com/CaptainPRICE/gmod-fakeoverlay/wiki/Extensibility).

# Legal
Licensed under the terms of the MIT license.
```
Copyright (c) 2016 https://github.com/CaptainPRICE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
