---
type: blog-post
title: Specifications vs Algorithms in Haskell
date: 2015-03-20
tags: specifications, algorithms, haskell, functional programming
---
Something I enjoy about learning a new subject is coming to a realization that's so obvious to the cognoscenti as to be scarcely worth mentioning. Fortunately Richard Bird in his [Pearls of Functional Algorithm Design](http://www.amazon.com/Pearls-Functional-Algorithm-Design-Richard/dp/0521513383) mentioned it anyway:

> Many, though by no means all, of the pearls start with a specification in Haskell and then go on to calculate a more efficient version. My aim in writing these particular pearls is to see to what extent algorithm design can be cast in a familiar mathematical tradition of calculating a result by using well-established mathematical principles, theorems and laws. While it is generally true in mathematics that calculations are designed to simplify complicated things, in algorithm design it is usually the other way around: simple but inefficient programs are transformed into more efficient versions that can be completely opaque. It is not the final program that is the pearl; rather it is the calculation that yields it. &mdash; Richard Bird, *Pearls of Functional Algorithm Design* (page x).

(Apparently [I'm not the only one](http://www.atamo.com/blog/how-to-read-pearls-by-richard-bird-1/) who zeroed in on this passage.)

Initially I was having difficulty resolving (in a functional programming context) the desires for [beautifully elegant code](2015-03-16-haskell-reveals-the-essence-of-quicksort.html) and computationally efficient code. The answer, obvious in retrospect, is that they generally aren't the same thing, whether in functional programming or elsewhere. You start with an elegant and (say) slow *specification*, and transform it into a less elegant but faster *algorithm*.

## An example

Bird's first pearl, called *The smallest free number*, illuminates the point. The goal is to design an algorithm that yields the smallest natural number not in a given set.

Here's the function specification:

~~~ haskell
import Data.List

minfree :: [Int] -> [Int]
minfree xs = head ([0..] \\ xs)
~~~

(In the book Bird uses the type `Nat`, but I wasn't able to get that to work, even after importing `GHC.TypeLits`. So I'm just using `Int`.)

From a specification perspective this is easy to understand. But as an algorithm it's a slow &Theta;(*n*<sup>2</sup>). Consider `minfree [4,3,2,1,0]`:

~~~
Compare 0 to 4, 3, 2, 1, 0. (Match, remove 0.)
Compare 1 to 4, 3, 2, 1.    (Match, remove 1.)
Compare 2 to 4, 3, 2.       (Match, remove 2.)
Compare 3 to 4, 3.          (Match, remove 3.)
Compare 4 to 4.             (Match, remove 4.)
Compare 5 to 4, 3, 2, 1, 0. (No match, 5 is the result.)
~~~

With some insight and calculation, we can do better with &Theta;(*n*).

One approach involves the insight is that *minfree* must be in [0..n], where *n* = *length xs*. (Think about it.)

The corresponding calculation involves building a checklist for the elements in [0..n] in linear time, and then doing a linear search for the first "unchecked" element. The overall result is a linear search.

I won't go into the details involved in developing the calculation [(buy the book)](http://www.amazon.com/Pearls-Functional-Algorithm-Design-Richard/dp/0521513383), but here's the final algorithm that it yields:

~~~ haskell
import Data.Array

minfree :: [Int] -> Int
minfree = search . checklist

checklist :: [Int] -> Array Int Bool
checklist xs = accumArray (||) False (0, n)
               (zip (filter (<= n) xs) (repeat True))
               where n = length xs

search :: Array Int Bool -> Int
search = length . takeWhile id . elems
~~~

While this isn't exactly a monster algorithm, neither is it a straightforward expression of the idea behind the function. That's the specification's job.
