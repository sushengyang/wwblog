---
type: blog-post
title: "Four Flavors of Functional Programming with Map and Filter"
date: 2015-03-10
tags: haskell, java, javascript, ruby, functional programming, language comparison
---

Mapping and filtering are two of the more important list operations in functional programming. They offer an alternative to loops in imperative programming. In this post we'll take a look at their use in Java 8, JavaScript, Ruby and Haskell.

This is intended more as a survey than as an evaluation. (That's not to say I don't have a favorite.) The approaches are more similar than they are different. Still the differences are interesting in that they reflect different characteristics of the languages under consideration.

## The functions

**Map.** The `map` function takes a function *f* and a list *L*, and returns a list containing the result of applying *f* to the individual elements of *L*.

As a simple example, consider the function *f(x)* = 2*x*, and *L* = [0, 1, 2, 3]. Applying `map` yields the result [0, 2, 4, 6].

Because `map` takes a function as an input, it's a higher-order function.

**Filter.** Another higher-order function is the `filter` function. This takes a predicate (the filter) and a list as inputs, and returns the filtered list as an output.

For instance, we might apply the filter `i >= 10` to the list [0, 10, 4, 13] to get the result [10, 13].

In the examples that follow, we'll use `map` and `filter` to write code that computes the first handful of even squares: 0, 4, 16, 36, 64.

## Java 8

Let's look at Java 8 first. Java 8 introduces support for lambda expressions and streams, which allows us to do mapping and filtering.

~~~ java
List<Integer> evenSquares = IntStream.rangeClosed(0, 9)
        .boxed()
        .map(i -> i * i)
        .filter(i -> i % 2 == 0)
        .collect(Collectors.toList());
~~~

`IntStream` is an interface, but Java 8 allows static methods on interfaces. So `IntStream.rangeClosed(0, 9)` generates a stream of integers 0, ..., 9. The `boxed()` call allows us to eventually collect the even squares up into a `List<Integer>`.

The `map` and `filter` methods are the ones we care about. Each takes a lambda expression specifying the mapping and filtering operations, respectively.

## JavaScript

JavaScript follows the same basic idea, but looks a little different:

~~~ javascript
var evenSquares = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        .map(function(i) { return i * i; })
        .filter(function(i) { return i % 2 == 0; });
~~~

The JavaScript version is clean and easy to follow. One minor nit is that I'd prefer lambda expressions over function expressions here, but no big deal. With JavaScript we don't have to mess around with generics or an explicit collection operation, which is a plus.

In this example we have a combination of object orientation and functional programming. The array's prototype has `map` and `filter` methods (that's the OO part) that accept functions (that's the FP part).

## Ruby

Now for Ruby:

~~~ ruby
even_squares = (0..9)
        .map { |i| i * i }
        .select { |i| i % 2 == 0 }
~~~

The Ruby version is nice and terse, owing to the concision of the block syntax. It's very easy to read once you understand the syntax.

Ruby uses (0..9) as the array range shorthand. And as with the JavaScript example, we combine object orientation and functional programming, since `map` and `select` are array methods.

Strictly speaking, we're not passing functions to `map` and `select`: the blocks `|i| i * i` and `|i| i % 2 == 0` are purely syntactic constructions. Ruby does however support explicit lambdas and procedures, which are real objects. See [this post](http://awaxman11.github.io/blog/2013/08/05/what-is-the-difference-between-a-block/) for more information.

## Haskell

Finally we have Haskell's pure functional approach. I'll show a couple ways to implement our example, just because it's fun to see what you can do with purely functional languages.

Here's the first one, which again is very terse:

~~~ haskell
evenSquares = filter (\i -> i `mod` 2 == 0) (map (\i -> i * i) [0..9])
~~~

Unpacking this a bit:

~~~ haskell
squares = map (\i -> i * i) [0..9]
evenSquares = filter (\i -> i `mod` 2 == 0) squares
~~~

In the example above, `squares` is a specific list of integers, and `evenSquares` is too. Suppose though that we wanted to be able to treat (1) squaring, (2) filtering evens and (3) squaring-then-filtering-evens as reusable functions to be applied to arbitrary lists of integers. We can use *partial function application* to generate functions for the first two, and *function composition* to generate a function for the third based on the first two:

~~~ haskell
square = map (\i -> i * i)
filterEvens = filter (\i -> i `mod` 2 == 0)
squareAndFilterEvens = filterEvens . square
~~~

This shows how straightforward it is in Haskell to generate new functions from old ones. The `square` function narrows `map` by fixing the mapping function but leaving the list argument untouched. Similarly `filterEvens` (which I'm thinking I should have called `filterOdds`) narrows `filter` again by fixing the filtering function but leaving the list argument untouched. Finally, function composition allows us to combine the two into a new function `squareAndFilterEvens` that we can reuse as we please.

I'll use the ghci shell to illustrate their use:

~~~ haskell
ghci> square [0..9]
[0,1,4,9,16,25,36,49,64,81]
ghci> square [0..15]
[0,1,4,9,16,25,36,49,64,81,100,121,144,169,196,225]
ghci> filterEvens [0..9]
[0,2,4,6,8]
ghci> filterEvens [0..15]
[0,2,4,6,8,10,12,14]
ghci> squareAndFilterEvens [0..15]
[0,4,16,36,64,100,144,196]
~~~

In the Haskell example, as opposed to the previous examples, we're doing pure functions. The `map`, `filter`, `square`, `filterEvens` and `squareAndFilterEvens` functions all stand alone. They aren't methods we call on array or list objects.
