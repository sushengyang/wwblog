---
type: blog-post
title: Haskell Reveals the Essence of Quicksort
date: 2015-03-16
tags: quicksort, algorithms, haskell, functional programming
---
I just ran across the following Haskell quicksort implementation, courtesy of [Wikibooks](http://en.wikibooks.org/wiki/Algorithm_Implementation/Sorting/Quicksort):

~~~ haskell
qsort [] = []
qsort (x:xs) = qsort (filter (<= x) xs) ++ [x] ++ qsort (filter (> x) xs)
~~~

This recursive definition is dense but easy to follow. The first line is the base case. In the second line, `x` is the first element and `xs` is the rest of the list. Using `x` as the pivot, we concatenate the sorted lower elements, the pivot and the sorted higher elements.

Here it is in action:

~~~ haskell
ghci> qsort [9,22,1,23,0,-12,3,44,5,4,5,2,44,3,14,15,23]
[-12,0,1,2,3,3,4,5,5,9,14,15,22,23,23,44,44]
~~~

To be sure, this isn't an optimized implementation. For example, it doesn't choose either a central or a random pivot, so it performs poorly with lists that are already sorted. And it does two passes through the `xs` at each recursion instead of one.

Still, it's pretty great how the tiny but dense code "captures" quicksort. It's eye-opening to compare it to implementations in other languages.
