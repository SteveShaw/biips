Windows
=============

Install rbiips
--------------
* **Requirements**: R (>= 3.0) with Rcpp package

* [Download](https://alea.bordeaux.inria.fr/biips/doku.php?id=download) rbiips

* Install rbiips package from R console:

```
install.packages('path/to/rbiips_X.X.X.zip')
```

Install matbiips
----------------
* **Requirements**:

    - Matlab: Windows (x64), Matlab (>=R2011a), [Visual C++ Redistributable for Visual Studio (x64)](http://www.microsoft.com/en-US/download/details.aspx?id=30679)
    - Octave: Windows (x86 or x64), Octave (MinGW, x86, >=3.6.4)

* [Download](https://alea.bordeaux.inria.fr/biips/doku.php?id=download) matbiips for either Matlab or Octave

* Extract matbiips archive

* Before using matbiips, you need to add the directory to the Matlab/Octave search path by typing in Matlab/Octave console:

```
addpath('path/to/matbiips')
```

-------------------------------------------------------------------------------

Mac OS X
============

Install rbiips
--------------
* **Requirements**: R (>= 3.0) with Rcpp package

* [Download](https://alea.bordeaux.inria.fr/biips/doku.php?id=download) rbiips

* Install rbiips package from R console:

```
install.packages('path/to/rbiips_X.X.X.tgz')
```

Install matbiips
----------------
* **Requirements**:

    - Matlab (>=R2011a)
    - Octave (>=3.6.4)

* [Download](https://alea.bordeaux.inria.fr/biips/doku.php?id=download) matbiips for either Matlab or Octave

* Extract matbiips archive

* Before using matbiips, you need to add the directory to the search Matlab/Octave path by typing in Matlab/Octave console:

```
addpath('path/to/matbiips')
```

-------------------------------------------------------------------------------

Linux
=============

Install rbiips from binary
--------------------------
* **Requirements**: Debian/Ubuntu, R (>= 3.0) with Rcpp package

* [Download](https://alea.bordeaux.inria.fr/biips/doku.php?id=download) rbiips

* Install rbiips package from R console:

```
install.packages('path/to/rbiips_x.x.x_R_x86_64-pc-linux-gnu.tar.gz')
```

Install rbiips from source
--------------------------
* **Requirements**: biips, R (>= 3.0) with Rcpp package

* [Download](https://alea.bordeaux.inria.fr/biips/doku.php?id=download) rbiips

* Install rbiips package from linux terminal:

If biips was installed as root in the standard paths:

```
R CMD INSTALL rbiips_X.X.X.tar.gz
```

Else, if biips was installed in local paths:

```
env BIIPS_INCLUDE=path/to/biips/include/biips/ BIIPS_LIB=/path/to/biips/lib/ARCH R CMD INSTALL rbiips_X.X.X.tar.gz
```

Install matbiips
----------------
* **Requirements**: Debian/Ubuntu, No previous biips installation is needed for matbiips

    - Matlab (>=R2011a)
    - Octave (>=3.6.4)

* [Download](https://alea.bordeaux.inria.fr/biips/doku.php?id=download) matbiips for either Matlab or Octave

* Extract matbiips archive

```
tar -xvzf matbiips_X.X.X.tar.gz
```

* Start Matlab using the following command:

```
LD_PRELOAD=/usr/libARCH/libstdc++.so.6 matlab
```

where `libARCH` is a directory depending on your Linux distribution and architecture, *e.g.*:

- on 64bit Debian/Ubuntu: `libARCH=lib/x86_64-linux-gnu`
- on 64bit Fedora/openSUSE/Mandriva/CentOS: `libARCH=lib64`

Note: alternatively to using the `LD_PRELOAD=...` command, you can rename the `path/to/MATLAB/R20XXx/sys/os/glnxa64/libstdc++.so.6` to e.g. `libstdc++.so.6.bak`.
This usually requires administrator permissions.

* Before using matbiips, you need to add the directory to the search Matlab path by typing in Matlab console:

```
addpath('path/to/matbiips')
```

Install biips from binary
-------------------------
* **Requirements**: Debian/Ubuntu, libboost-dev (>=1.49)

* [Download](https://alea.bordeaux.inria.fr/biips/doku.php?id=download) biips package

* Root installation from terminal:

```
sudo dpkg -i biips_X.X.X_Linux.deb
```

...or double-click on the deb file in your file browser. This will install it as root in `/usr/` directory.

* Local installation from terminal:

```
dpkg-deb -x biips_X.X.X.deb  path/to/biips
```

* Other Linux distributions:
    - OpenSuse: `sudo rpm -i biips_x.x.x_Linux.rpm`
    - Mandriva: `sudo urpmi biips_x.x.x_Linux.rpm `

Install biips from sources
--------------------------
* **Requirements**:
    - git
    - cmake
    - gcc (>= 4.7)
    - boost (>=1.49.0)
    - R (>= 3.0) + Rcpp package
    - Matlab or Octave

* [Download](https://alea.bordeaux.inria.fr/biips/doku.php?id=download) biips sources

* Extract source archive

```
tar -xvzf path matbiips_X.X.X.tar.gz path/to/sources
```

* Configure

```
mkdir path/to/build
cd path/to/build
cmake -DCMAKE_INSTALL_PREFIX=/path/to/install -DCMAKE_BUILD_TYPE=Release path/to/sources
```

* Compile

```
make -jN (where N = number of parallel jobs)
```

* Install

```
make install
```

* Test

```
make test
```

Note: If you lose control of your terminal during the tests, type

```
stty echo
```

