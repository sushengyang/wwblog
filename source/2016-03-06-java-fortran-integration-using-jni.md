---
type: blog-post
title: Java/Fortran Integration Using JNI
date: 2016-03-06
tags: java, fortran, c, jni, gradle
published: true
---
While Java/Fortran integration isn't something I expect to have to do very
often, I recently needed to do this, and so I figured I'd write it up in case
somebody else finds it helpful.

Also, please see
[Calling FORTRAN and C from Java](http://www.csharp.com/javacfort.html) for
additional information. My post borrows a lot from that article.

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

If you're using Gradle, be sure to apply the Java plugin:

~~~ groovy
apply plugin: 'java'
~~~

# Approach outline

As I noted above, we use JNI for the integration. But for me one surprise was
that we have to create a C adapter that sits between the Java and Fortran code.
Basically Java calls the C adapter, which forwards the call to Fortran.

So here's the outline.

1. Compile the Fortran code.
2. Update the Java code so that it can load and call the native C and Fortran
   code.
3. Create a C adapter to bridge the Java and Fortran code.
4. Create a native library containing the C and Fortran code.
5. Run the Java against the native library.

# Step 1. Compile the Fortran code

In bash, this is pretty easy:

~~~ shell
$ mkdir -p build/fortran
$ gfortran -o build/fortran/stl.o -c src/main/fortran/stl.f
~~~

In Gradle it's, well, more:

~~~ groovy
task prepareFortran(type: Exec) {
  commandLine 'mkdir', '-p', "${buildDir}/fortran"
}

task compileFortran(type: Exec) {
  def src = file("src/main/fortran/stl.f")
  def obj = file("${buildDir}/fortran/stl.o")

  group "Build"
  description "Compiles the Fortran sources."
  commandLine 'gfortran', '-o', obj, '-c', src
  dependsOn prepareFortran
}
~~~

# Step 2. Update the Java code to make the native call

The idea here is to give the Java code the ability to load and call the JNI
library, which contains the C and Fortran code.

In my case, I have this:

~~~ java
package com.example.stl;

public class Stl {

  // Load the dynamic library libstl_driver.jnilib (OSX only).
  static {
    System.loadLibrary("stl_driver");
  }

  // Native C method that we want to be able to call from Java.
  private native int stlc(float[] y, int np, int ns, int nt, int nl,
      int isdeg, int itdeg, int ildeg, int nsjump, int ntjump, int nljump,
      int no, int ni, float[] rw, float[] season, float[] trend);

  // Whatever Java methods we want
  public StlResult decompose(final float[] y) {

    ... whatever Java code ...

    // Call the native method
    int status = stlc(y, np, ns, nt, nl, isdeg, itdeg, itldeg, nsjump,
        ntjump, nljump, no, ni, rw, season, trend);

    ... whatever Java code ...
  }
}
~~~

Gradle automatically compiles this for us since we're using the Java plugin.

# Step 3. Create the C adapter

Here the goal is to create a C adapter that bridges the Java and Fortran sides.

First, run `javah` on the compiled Java class to extract a C header file. This
is extracted from the native method we defined in step 2 above.

~~~ groovy
task prepareC(type: Exec) {
  commandLine 'mkdir', '-p', "${buildDir}/c"
}

task generateJniHeaders(type: Exec) {
  def classpath = sourceSets.main.output.classesDir
  def jniHeadersDir = file("${buildDir}/c/jni-headers")

  group "Build"
  description "Generates the JNI headers."
  commandLine 'javah' ,'-d', jniHeadersDir, '-classpath', classpath,
      'com.example.stl.Stl'
  dependsOn classes, prepareC
}
~~~

Now we need an adapter, written in C and conforming to the JNI header file we
just generated, that calls the Fortran code.

~~~ c
#include <stdio.h>
#include "com_example_stl_Stl.h"

// Prototype Fortran routines as extern, and we pass params to Fortran by
// reference. Name mangling for gfortran is Fortran lowercase routine name
// (here, "stl") + "_".
extern void stl_(
    float [],   // y
    int *,      // n
    int *,      // np
    int *,      // ns
    int *,      // nt
    int *,      // nl
    int *,      // isdeg
    int *,      // itdeg
    int *,      // ildeg
    int *,      // nsjump
    int *,      // ntjump
    int *,      // nljump
    int *,      // ni
    int *,      // no
    float [],   // rw
    float [],   // season
    float [],   // trend
    float [][7] // work
);

// Note the name mangling here. Instead of main(), this function is
// "Java_" + mangled_fully_qualified_class_name + "_" + C function that
// Java calls.
JNIEXPORT jint JNICALL Java_com_example_stl_Stl_stlc(
      JNIEnv *env,         /* interface pointer */
      jobject obj,         /* "this" pointer */
      jfloatArray jy,
      jint np,
      jint ns,
      jint nt,
      jint nl,
      jint isdeg,
      jint itdeg,
      jint ildeg,
      jint nsjump,
      jint ntjump,
      jint nljump,
      jint no,
      jint ni,
      jfloatArray jrw,
      jfloatArray jseason,
      jfloatArray jtrend)
{

  jsize n = (*env)->GetArrayLength(env, jy);
  jfloat *y = (*env)->GetFloatArrayElements(env, jy, 0);
  jfloat *rw = (*env)->GetFloatArrayElements(env, jrw, 0);
  jfloat *season = (*env)->GetFloatArrayElements(env, jseason, 0);
  jfloat *trend = (*env)->GetFloatArrayElements(env, jtrend, 0);
  float work[n + 2 * np][7];

  for (int i = 0; i < n + 2 * np; i++) {
    for (int j = 0; j < 7; j++) {
      work[i][j] = 0.0;
    }
  }

  // Call the Fortran routine.
  stl_(y, &n, &np, &ns, &nt, &nl,
    &isdeg, &itdeg, &itdeg,
    &nsjump, &ntjump, &nljump,
    &no, &ni,
    rw, season, trend, work);

  // Clear the pointers before returning to Java.
  (*env)->ReleaseFloatArrayElements(env, jy, y, 0);
  (*env)->ReleaseFloatArrayElements(env, jrw, rw, 0);
  (*env)->ReleaseFloatArrayElements(env, jseason, season, 0);
  (*env)->ReleaseFloatArrayElements(env, jtrend, trend, 0);

  return 0;
}​
~~~

You'll also need to add a Gradle task to compile the C code:

~~~ groovy
task compileC(type: Exec) {
  def sysHeadersDir =
      file("/System/Library/Frameworks/JavaVM.framework/Headers")
  def jniHeadersDir = file("${buildDir}/c/jni-headers")
  def src = file("src/main/c/stl.c")
  def obj = file("${buildDir}/c/stl.o")

  group "Build"
  description "Compiles the C sources."
  commandLine 'gcc', '-c', '-o', obj, '-I', sysHeadersDir,
      '-I', jniHeadersDir, src
  dependsOn generateJniHeaders
}
~~~

Perhaps a bit confusingly, here I'm giving the C binary the name `stl.o`, just
like I did with the Fortran binary. They're in different directories though.

# Step 4. Create the JNI library

Now we want to package the C and Fortran code in a way that Java can use it.

~~~ groovy
task prepareJniLib(type: Exec) {
  commandLine 'mkdir', '-p', "${buildDir}/libs"
}

task buildJniLib(type: Exec) {
  def fortranLib = file("/usr/local/lib/gcc/5/libgfortran.dylib")
  def jniLib = file("${buildDir}/libs/libstl_driver.jnilib")

  group "Build"
  description "Builds the JNI library."
  commandLine(
    'gcc', '-dynamiclib', '-o', jniLib, fortranLib,
    "${buildDir}/fortran/stl.o", "${buildDir}/c/stl.o",
    '-framework', 'JavaVM')
  dependsOn compileFortran, compileC, prepareJniLib
}

build.dependsOn buildJniLib
~~~

# Step 5. Run the Java

After this, you should be able to run the Java code.
