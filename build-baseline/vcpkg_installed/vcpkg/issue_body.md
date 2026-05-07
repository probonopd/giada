Package: alsa:x64-linux@1.2.15.3#1

**Host Environment**

- Host: x64-linux
- Compiler: GNU 13.3.0
- CMake Version: 4.2.3
-    vcpkg-tool version: 2026-04-08-e0612b42ce44e55a0e630f2ee9d3c533a63d8bc1
    vcpkg-scripts version: b80e006657 2026-04-13 (3 weeks ago)

**To Reproduce**

`vcpkg install `

**Failure logs**

```
alsa currently requires the following programs from the system package manager:
    autoconf autoheader aclocal automake libtoolize
On Debian and Ubuntu derivatives:
    sudo apt install autoconf libtool
On recent Red Hat and Fedora derivatives:
    sudo dnf install autoconf libtool
On Arch Linux and derivatives:
    sudo pacman -S autoconf automake libtool
On Alpine:
    apk add autoconf automake libtool
Downloading https://github.com/alsa-project/alsa-lib/archive/v1.2.15.3.tar.gz -> alsa-project-alsa-lib-v1.2.15.3.tar.gz
Successfully downloaded alsa-project-alsa-lib-v1.2.15.3.tar.gz
-- Extracting source /usr/local/share/vcpkg/downloads/alsa-project-alsa-lib-v1.2.15.3.tar.gz
-- Applying patch fix-plugin-dir.patch
-- Applying patch libdl.diff
-- Using source at /usr/local/share/vcpkg/buildtrees/alsa/src/v1.2.15.3-f23c25925a.clean
-- Getting CMake variables for x64-linux
-- Loading CMake variables from /usr/local/share/vcpkg/buildtrees/alsa/cmake-get-vars_C_CXX-x64-linux.cmake.log
CMake Error at /home/runner/work/giada/giada/build-baseline/vcpkg_installed/x64-linux/share/vcpkg-make/vcpkg_make.cmake:108 (message):
  alsa currently requires the following programs from the system package
  manager:

      autoconf autoconf-archive automake libtoolize



      On Debian and Ubuntu derivatives:
          sudo apt install autoconf autoconf-archive automake libtool
      On recent Red Hat and Fedora derivatives:
          sudo dnf install autoconf autoconf-archive automake libtool
      On Arch Linux and derivatives:
          sudo pacman -S autoconf autoconf-archive automake libtool
      On Alpine:
          apk add autoconf autoconf-archive automake libtool
      On macOS:
          brew install autoconf autoconf-archive automake libtool

Call Stack (most recent call first):
  /home/runner/work/giada/giada/build-baseline/vcpkg_installed/x64-linux/share/vcpkg-make/vcpkg_make_configure.cmake:66 (vcpkg_run_autoreconf)
  buildtrees/versioning_/versions/alsa/f816bc653d9b4942df8c704837de9d88c1ae330f/portfile.cmake:40 (vcpkg_make_configure)
  scripts/ports.cmake:206 (include)



```

**Additional context**

<details><summary>vcpkg.json</summary>

```
{
  "name": "giada",
  "version-string": "1.0",
  "builtin-baseline": "c3867e714dd3a51c272826eea77267876517ed99",
  "dependencies": [
    "fmt",
    "catch2",
    "nlohmann-json",
    "libsamplerate",
    {
      "name": "rtmidi",
      "platform": "linux",
      "features": [
        "alsa"
      ]
    },
    {
      "name": "rtmidi",
      "platform": "!linux"
    },
    {
      "name": "libsndfile",
      "features": [
        "external-libs"
      ]
    }
  ],
  "overrides": [
    {
      "name": "fmt",
      "version": "12.0.0"
    },
    {
      "name": "rtmidi",
      "version": "6.0.0"
    },
    {
      "name": "catch2",
      "version": "3.11.0"
    },
    {
      "name": "libsamplerate",
      "version": "0.2.2"
    },
    {
      "name": "nlohmann-json",
      "version": "3.12.0"
    },
    {
      "name": "libsndfile",
      "version": "1.2.2"
    }
  ]
}

```
</details>
