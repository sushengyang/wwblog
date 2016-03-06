---
type: blog-post
title: Java/Fortran Integration Using JNI
date: 2016-03-06
tags: java, fortran, c, jni, gradle
published: false
---
While Java/Fortran integration isn't something I expect to have to do very
often, I recently needed to do this, and so I figured I'd write it up in case
somebody else finds it helpful.

# Assumptions

Here's our starting point:

- You have the Fortran 77 source code.
- You have the Java source code that wants to call the Fortran code.
- You want a single Gradle build at the end.
- You're on Mac OS X. (I'm using 10.11.1 for this post.)

You probably have your own Fortran code that you want to use. If you don't, you
can use the Fortran 77 code I'm using [(link)](http://www.netlib.org/a/stl),
which is an algorithm called STL. That file is actually a whole bunch of files
all merged together, so you'll need to find the `stl.f` part of the file and
isolate it. You'll also need to remove all the hyphens from the beginning of the
line, which aren't part of the Fortran code.

If you don't care about Gradle, that's fine. The bash equivalents will be pretty
obvious below.

The Mac OS X part matters because (SPOILER ALERT) the integration involves JNI,
and that means that there's a platform-dependent aspect to the integration.
Still the general outline of the approach is the same across platforms, so you
should be able to use this with modifications even if you're on some other
platform.

# Setup

You're going to need a Fortran compiler, and as it turns out a C compiler too.
I'm using `gfortran` and `gcc` respectively. I *believe* that `gfortran`
actually comes with `gcc` nowadays but I'm not positive about that.

# Approach outline

As I noted above, we use JNI for the integration. But for me one surprise was
that we have to create a C adapter that sits between the Java and Fortran code.
Basically Java calls the C adapter, which forwards the call to Fortran.

So here's the outline:

### Fortran part
1. Compile the Fortran code.

### Java part
2. Add Java code to load the JNI library that we're going to build. This library
   contains both the C adapter and the Fortran code we're calling.
3. Add the C native method to the Java code. This is how Java calls C.
4. Compile the Java code.

### C part
5. Run `javah` on the compiled Java class to extract a C header file. This is
   extracted from the native method from step 3 above.
6. Write a C adapter, conforming to the header file, that calls the Fortran.
7. Compile the C adapter code.

### JNI library part
8. Create a JNI library that contains the Fortran and C binaries we created
   above.

### Run the Java
9. Run the Java code. It loads the JNI library we created (see steps 2 and 8
   above), and then calls the C adapter method (see step 3 above). The C method
   in turn calls the Fortran subroutine (see step 6 above).
