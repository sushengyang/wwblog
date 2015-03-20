---
type: blog-post
title: Haskell Math Geekery
date: 2015-03-09
tags: haskell, math, functional programming, language comparison
---

Recently I watched Larry Wall's 2011 video on [five programming languages everyone should know](https://www.youtube.com/watch?v=LR8fQiskYII). Overall the recommendations are plausible enough, even in 2015:

* **JavaScript.**
* **Java**, though he's clearly not a fan.
* **Haskell**, because it's a pure functional language that's totally different than the others.
* **C**, to get down in the machine.
* **A scripting language.** He likes Perl, obviously, but he considers Python and Ruby legitimate choices here too.

Of the five, Haskell was the only one I'd never used, so I thought I'd take a look.

## Haskell looks like math

As an undergraduate I was a math major, and one of the first things that struck me about Haskell is how much the code "looks like math". Specifically, when you define functions, you define them more or less the way you'd define them if you were writing a math book.

Here are a couple of examples from the book [The Haskell Road to Logic, Maths and Programming (2e)](http://www.amazon.com/Haskell-Programming-Second-Edition-Computing/dp/0954300696) (with trivial modifications). First, here's a function to find the minimum integer in a list of integers:

~~~ haskell
minInt :: [Int] -> Int
minInt [] = error "empty list"
minInt [x] = x
minInt (x:xs) = min x (minInt xs)
~~~

Though I come from a Java background, I felt immediately at home with this code. The first line is a function signature. (I don't know if that's what they call it in Haskell, but that's what it is.) We have a function `minInt` that takes a list of integers as an input and returns a single integer as an output. Then we have a recursive definition:

* Applying `minInt` to an empty list is undefined.
* Applying `minInt` to a singleton list returns the single element.
* Applying `minInt` to a larger list returns the minimum of the list head `x` and `minInt` applied to the list tail `xs`.

That is bad-ass!

In the `minInt` example we use Haskell's built-in `min` function to get the minimum of two integers. The *Haskell Road* book shows how to define a homegrown version `min'`, and this will be our second example:

~~~ haskell
min' :: Int -> Int -> Int
min' x y | x <= y    = x
         | otherwise = y
~~~

Again we have a function signature for `min'`. The way it works is that the last parameter is the return value, and anything before it is an argument. It looks a little funny if you're used to `(arg1, arg2, ..., argn)`, but that's how it works in Haskell.

After the signature we define `min` by showing how to apply it to integer arguments `x` and `y`. Here we have another very common approach to mathematical definition, which is separation by case:

* `min' x y` is `x` if `x <= y`;
* otherwise it's `y`.

I love it. But there's even more.

## Function composition

As great as the examples above are, from a conceptual point of view they're not *entirely* unlike something we might see in a nonfunctional context. The notation is different but the approach isn't totally different. Consider for example the Java version of `minInt`, done recursively:

~~~ java
public static int minInt(int[] list) {
  if (list.length == 0) {
    throw new IllegalArgumentException("empty list");
  }
  return minInt(list, 0);
}

// Use startIndex to avoid array copying
private static int minInt(int[] list, int startIndex) {
  int head = list[startIndex];
  if (startIndex == list.length - 1) {
    return head;
  } else {
    return Math.min(head, minInt(list, startIndex + 1));
  }
}
~~~

While the Java version is definitely more verbose than the Haskell version, the logic is the same. In both cases we define the function by describing how we want to manipulate the inputs.

But in Haskell as in math there's another way to define functions.

If you go to [Problem 2](https://wiki.haskell.org/99_questions/1_to_10) of [Ninety-Nine Haskell Problems](https://wiki.haskell.org/99_questions), there's a problem to find the penultimate element in a list. Here's the newbie way I did it:

~~~ haskell
penultimate :: [a] -> a
penultimate [] = error "empty list"
penultimate [x] = error "list must have at least two elements"
penultimate [x, y] = x
penultimate (x:xs) = penultimate xs
~~~

(`a` is a generic type parameter. We could have used integers again, but finding the penultimate list element isn't tied to integers at all, so I just went with a generic type.)

My code works. But then I looked at the solution:

~~~ haskell
penultimate :: [a] -> a
penultimate = last . init
~~~

Eh? [What's that dot?](http://stackoverflow.com/questions/631284/dot-operator-in-haskell-need-more-explanation)

It's **function composition**! Again, just like in math.

Here's what's going on. Haskell has the following built-in list functions (among many others):

* **head** : return the first element of a list
* **tail** : return everything after the first element of a list
* **init** : return everything but the last element of a list
* **last** : return the last element of a list

It's easy to see that `last . init` yields the desired result.

Haskell, like JavaScript but unlike Java [(at least pre Java 8)](http://stackoverflow.com/questions/15221659/java-8-lambda-expression-and-first-class-values), treats functions as first-class objects, so we can do things like pass them around and compose them. (I expect that the dot operator is simply a higher-order function that takes two suitably-typed functions as arguments and spits out another function.) This approach, common in mathematics, is one of the nice features that functional programming offers.
