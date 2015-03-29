---
type: blog-post
title: Folding in Haskell
date: 2015-03-28
tags: haskell, functional programming
---

In [Four Flavors of Functional Programming with Map and Filter](2015-03-10-four-flavors-functional-programming-map-filter.html) we looked at `map` and `filter`, two higher-order functions for list processing. This time around we'll look at *folding*, which has two main varieties. The first is called `foldl`, or left fold, and it processes the list from left to right. The other is `foldr` and has the corresponding behavior.

## foldl

The idea with folding is that sometimes we want to process a list in such a way as to yield some accumulated result. For example, if we have a list of numbers, then we might want to calculate their sum. Now we can certainly do this without folding. Here's a recursive approach:

~~~ haskell
sum' :: (Num a) => [a] -> a
sum' [] = 0
sum' [x] = x
sum' (x:xs) = x + sum' xs
~~~

Here's one way to do this with `foldl`:

~~~ haskell
foldlSum :: (Num a) => [a] -> a
foldlSum = foldl (\acc x -> acc + x) 0
~~~

`foldl` takes three arguments:

* A two-arg step function to step through the list, folding the current element into the accumulated value. The first argument is the accumulator and the second is the element we're processing.
* An initial value for the accumulation.
* A list.

At the end `foldl` returns the accumulated value.

The step function combines a given list element with the current accumulated value to produce a new accumulated value. In the example above it simply adds the list element `x` to `acc`.

Incidentally, since our lambda expression is really just a sum, we can recast `foldlSum` more economically as

~~~ haskell
foldlSum :: (Num a) => [a] -> a
foldlSum = foldl (+) 0
~~~

That makes it pretty clear what this function is doing. Basically it says to initialize the sum at 0, and gobble up list elements from the left, accumulating using `(+)`.

## foldr

I mentioned above that there's a `foldr` function that processes the list from right to left. Given the examples above, you might wonder what difference it makes. Whether we compute the sum from left to right or right to left, the result is the same, and the performance characteristics are the same.

It turns out though that there are cases where `foldr` is helpful. One kind of example is where we're generating a list. (Note that folding isn't restricted to generating scalars&mdash;we can generate lists or really anything else.) Suppose that we wanted to take a list and duplicate every element, so that **[3, 4, 3, 1, 0]** becomes **[3, 3, 4, 4, 3, 3, 1, 1, 0, 0]**. Here's how we can do this with `foldl`:

~~~ haskell
foldlDupList :: [a] -> [a]
foldlDupList = foldl (\acc x -> acc ++ [x] ++ [x]) []
~~~

This works, but we can do better. It is less expensive to build our list using `:` (prepending, or "consing") than it is using `++` (concatenation). But to do this we would need to use `foldr` to start from the right, and keep prepending the processed element to the accumulated list:

~~~ haskell
foldrDupList :: [a] -> [a]
foldrDupList = foldr (\x acc -> x: x: acc) []
~~~

Note that with `foldr`, the step functions arguments are reversed: that is, the first argument is the processed element, and the second is the accumulated value.

## foldl1 and foldr1

One interesting case is computing a maximum (or minimum). Take a look at this:

~~~ haskell
foldlMax :: (Ord a) => [a] -> a
foldlMax [] = error "empty list"
foldlMax (x:xs) = foldl step x xs
  where step acc x
          | x >= acc  = x
          | otherwise = acc
~~~

Notice that here we used the first element `x` as an initial value. That makes sense since we can't arbitrarily choose 0 as the maximum. (The list might contain only negative numbers.) Haskell has a special version of `foldl` called `foldl1` that initializes the accumulator with the first element of the list. Likewise there's a `foldr1` function that initializes the accumulator with the last element of the list. With `foldl1` we can define a new max function as follows:

~~~ haskell
foldl1Max :: (Ord a) => [a] -> a
foldl1Max = foldl1 max
~~~

As you can see, using `foldl1` (and `foldr1`) can significantly clean up a function definition for the common case were we want to initialize the accumulator with an existing list element.
