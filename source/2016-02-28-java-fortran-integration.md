---
type: blog-post
title: Java/Fortran Integration
date: 2016-02-28
tags: java, fortran
published: false
---
I recently needed to integrate an existing Fortran library into a Java app. I
thought I'd write it up since it's not something I've done before.

**Setup.** Make sure you have a Fortran 77 compiler. I'm on a Mac, and the gcc
gcc compiler comes with `gfortran`.

**Step 1.** Get the code:

    $ curl http://www.netlib.org/a/stl > stl-src.txt

**Step 2.** Isolate `stl.f`, and clean it up. The cleanup involves removing all
the `-` characters, and moving the `&` continuation character to column 6.

**Step 3.** Compile the `stl.f` library functions:

    $ gfortran -c stl.f

**Step 4.** Isolate `sample.f`, and perform the same cleanup as above.

**Step 5.** We're going to modify `sample.f` a bit.

TODO

**Step 6.** Compile `sample.f`:

    $ gfortran -o sample sample.f stl.o

**Step 7.** Isolate `co2.dat`. (The original file is called `co2`; I've renamed
it just to clarify that it's a data file. Totally up to you.)

**Step 8.** Run the data file through the algorithm:

    $ ./sample < co2.dat

## Reference

* [GNU Fortran: Using the compiler](https://gcc.gnu.org/wiki/GFortranUsage)
