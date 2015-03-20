---
type: blog-post
title: "Spring + MongoDB + AngularJS Starter"
date: 2015-03-15
tags: starter, java, spring, spring boot, spring data rest, mongodb, angularjs, bootstrap
published: true
---

<i class="fa fa-github fa-2x"></i> If you're impatient, you can [get this app at GitHub](https://github.com/williewheeler/spring-mongo-angular-starter).

This post shows how to set up a minimal starter application based on the following stack:

- Backend:
  - [Spring Boot](http://projects.spring.io/spring-boot/)
  - [Spring Data MongoDB](http://projects.spring.io/spring-data-mongodb/)
  - [Spring Data REST](http://projects.spring.io/spring-data-rest/)
  - [MongoDB](http://www.mongodb.org/)
  - [Project Lombok](http://projectlombok.org/) (optional)
- Frontend:
  - [AngularJS](https://angularjs.org/)
  - [Bootstrap](http://getbootstrap.com/) (optional)
  - [Font Awesome](http://fortawesome.github.io/Font-Awesome/) (optional)

Along the way I explain how to do without Project Lombok if you decide you don't want it. The other optional dependencies are just dependencies that I like to use, but they're super easy to remove if you don't want them.

**This is a starter app, not a demo of the technologies involved.** So the "app" is minimal. It has a REST API for manipulating songs, along with a single UI page for displaying them.

## Prerequisites

For this tutorial you'll need Java, [Gradle](https://gradle.org/) and [MongoDB](http://www.mongodb.org/). With Homebrew on Mac:

~~~
$ brew install gradle
$ brew install mongodb
~~~

If you decide to use Project Lombok, then you'll need to run its executable JAR for your IDE.

You'll also find it useful to have some kind of REST client. For Chrome you can use the Advanced REST Client. Or you can use curl if you like.

## Step 1. Project Setup

Use the Gradle Built Init plugin to set up a new project. Here I'm calling it `spring-mongo-angular-starter`; substitute whatever project name you like.

~~~
$ mkdir spring-mongo-angular-starter
$ cd spring-mongo-angular-starter/
$ gradle init --type=java-library
:wrapper
:init

BUILD SUCCESSFUL

Total time: 0.673 secs
$ 
~~~

This generates a basic project skeleton. Replace `build.gradle` with the following:

~~~ groovy
buildscript {
  repositories {
    mavenCentral()
    maven { url 'http://repo.spring.io/plugins-release' }
  }
  dependencies {
    classpath(
      "org.springframework.boot:spring-boot-gradle-plugin:1.2.2.RELEASE",
      "org.springframework.build.gradle:propdeps-plugin:0.0.6"
    )
  }
}

apply plugin: 'java'
apply plugin: 'eclipse'
apply plugin: 'spring-boot'

configure(allprojects) {
  apply plugin: 'propdeps'
  apply plugin: 'propdeps-eclipse'
}

jar {
  baseName = 'spring-mongo-angular-starter'
  version =  '0.1.0'
}

repositories {
  mavenCentral()
}

ext {
  junitVersion = '4.12'
  springBootVersion = '1.2.2.RELEASE'
}

dependencies {
  compile(
    "org.springframework.boot:spring-boot-starter-data-mongodb:${springBootVersion}",
    "org.springframework.boot:spring-boot-starter-data-rest:${springBootVersion}",
    "org.springframework.boot:spring-boot-starter-web:${springBootVersion}"
  )
  testCompile("junit:junit:${junitVersion}")
  provided("org.projectlombok:lombok:1.16.2")
}

task wrapper(type: Wrapper) {
  gradleVersion = '2.3'
}
~~~

If you don't want Lombok, then simply remove the Lombok dependency from the build file. If you like, you can also remove the `propdeps-plugin`, the corresponding plugin configuration and the Spring plugin repo declaration in the `buildscript` section.

## Step 2. Create the REST API

In this step we'll build enough of the app to get the REST API working. This involves a small amount of Java code, app config and sample data.

First, delete the `Library.java` and `LibraryTest.java` classes that the Gradle Build Init plugin auto-created.

Now let's create a `Song` entity.

~~~ java
package com.williewheeler.songs.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import org.springframework.data.annotation.Id;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Song {
  @Id private String id;
  private String title;
  private String artist;
  private String album;
}
~~~

If you aren't using Lombok, then you'll need to add the constructors and accessors yourself.

Next we'll create a `SongRepo` repository.

~~~ java
package com.williewheeler.songs.repo;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.repository.query.Param;

import com.williewheeler.songs.entity.Song;

public interface SongRepo extends MongoRepository<Song, String> {
  
  Page<Song> findByArtist(
      @Param("artist") String artist,
      Pageable pageable);
}
~~~

Just for kicks I added a `findByArtist()` query method, though the UI won't use it. Still we can call it from the API though.

The last Java class is the application class:

~~~ java
package com.williewheeler.songs;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SongApp {
  
  public static void main(String[] args) {
    SpringApplication.run(SongApp.class, args);
  }
}
~~~

Now we're ready to run it. Create a `data` directory in the project's top-level directory and then start MongoDB:

~~~
$ mkdir data
$ mongod --dbpath=data
~~~

Then in a separate terminal window, start the app:

~~~
$ gradle bootRun
~~~

Finally, point your browser to **http://localhost:8080/songs**. You should see the following:

~~~ javascript
{
  "_links" : {
    "self" : {
      "href" : "http://localhost:8080/songs{?page,size,sort}",
      "templated" : true
    },
    "search" : {
      "href" : "http://localhost:8080/songs/search"
    }
  },
  "page" : {
    "size" : 20,
    "totalElements" : 0,
    "totalPages" : 0,
    "number" : 0
  }
}
~~~

There aren't any songs yet, but we can easily add one. Use your REST client to post the following to **http://localhost:8080/songs**:

~~~ javascript
{
  "id": "song001",
  "title": "Follow You, Follow Me (Live)",
  "artist": "Mark Kozelek",
  "album": "Live in Copenhagen"
}
~~~

After you do that, do a GET against the URL and you should get

~~~ javascript
{
  "_links" : {
    "self" : {
      "href" : "http://localhost:8080/songs{?page,size,sort}",
      "templated" : true
    },
    "search" : {
      "href" : "http://localhost:8080/songs/search"
    }
  },
  "_embedded" : {
    "songs" : [ {
      "title" : "Follow You, Follow Me (Live)",
      "artist" : "Mark Kozelek",
      "album" : "Live in Copenhagen",
      "_links" : {
        "self" : {
          "href" : "http://localhost:8080/songs/song001"
        }
      }
    } ]
  },
  "page" : {
    "size" : 20,
    "totalElements" : 1,
    "totalPages" : 1,
    "number" : 0
  }
}
~~~

## Step 3. Create the UI

Now that we have a REST API, we can implement a simple UI based on AngularJS and Bootstrap. I'm throwing Font Awesome in there too.

First things first. We need to "move" the API to its own path to avoid conflicts with the UI paths. That's easy. From the top-level directory, do this:

~~~
$ mkdir src/main/resources
$ cd src/main/resources
$ echo "spring.data.rest.base-uri: api" > application.yml
~~~

If you retry the API, you'll find that now you have to use **http://localhost:8080/api/songs**.

Now we need to create a series of files. Here's the entry point, **src/main/resources/static/index.html**:

~~~ html
<!DOCTYPE html>
<html lang="en" ng-app="songApp">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="Content-type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Song App</title>
    <base href="/">
    <link rel="stylesheet" type="text/css" href="//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.2/css/bootstrap.min.css">
    <link rel="stylesheet" type="text/css" href="//cdnjs.cloudflare.com/ajax/libs/font-awesome/4.3.0/css/font-awesome.min.css">
    <link rel="stylesheet" type="text/css" href="css/app.css">
  </head>
  <body>
    <div class="container">
      <h1>Songs <i class="fa fa-star"></i></h1>
      <ng-view></ng-view>
    </div>
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/angular.js/1.3.14/angular.min.js"></script>
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/angular.js/1.3.14/angular-route.min.js"></script>
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/angular-ui-bootstrap/0.12.1/ui-bootstrap.min.js"></script>
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/angular-ui-bootstrap/0.12.1/ui-bootstrap-tpls.min.js"></script>
    <script type="text/javascript" src="js/app.js"></script>
    <script type="text/javascript" src="js/controllers.js"></script>
  </body>
</html>
~~~

Next, here's the song list view, **src/main/resources/static/view/song-list.html**:

~~~ html
<div ng-controller="SongListController">
  <table class="table">
    <thead>
      <tr>
        <th>Title</th>
        <th>Artist</th>
        <th>Album</th>
      </tr>
    </thead>
    <tbody>
      <tr ng-repeat="song in songs._embedded.songs">
        <td ng-bind="song.title"></td>
        <td ng-bind="song.artist"></td>
        <td ng-bind="song.album"></td>
      </tr>
    </tbody>
  </table>
</div>
~~~

Here's the AngularJS app code, **src/main/resources/static/js/app.js**:

~~~ javascript
var songApp = angular.module('songApp', [ 'ngRoute', 'songControllers' ]);

songApp.config([ '$routeProvider', function($routeProvider) {
  $routeProvider
    .when('/', {
      controller: 'SongListController',
      templateUrl: 'view/song-list.html'
    });
} ]);
~~~

Next we have a single AngularJS controller in **src/main/resources/static/js/controllers.js**:

~~~ javascript
var songControllers = angular.module('songControllers', []);

songControllers.controller('SongListController', [ '$scope', '$http',
  function($scope, $http) {
    $http.get('/api/songs')
      .success(function(songs) { $scope.songs = songs; })
      .error(function() { alert("Couldn't load songs"); });
  } ]);
~~~

Finally, **src/main/resources/static/css/app.css**:

~~~ css
.fa.fa-star { color: #FFE11A; }
~~~

Now direct your browser at **http://localhost:8080** and you should see this:

<img class="figure img-responsive" src="https://db.tt/4nW63fmj" alt="Screenshot">

That's all there is to it. Remember that you can [get this app at GitHub](https://github.com/williewheeler/spring-mongo-angular-starter).
