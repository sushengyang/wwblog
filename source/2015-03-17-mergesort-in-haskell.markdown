---
type: blog-post
title: Mergesort in Haskell
date: 2015-03-17
tags: mergesort, algorithms, haskell, functional programming
---
After yesterday's post on [quicksort in Haskell](2015-03-16-haskell-reveals-the-essence-of-quicksort.html), I was curious whether mergesort is as elegant. Not quite, but I learned a bit along the way.

Here was my initial mergesort implementation:

~~~ haskell
msort :: (Ord a) => [a] -> [a]
msort [] = []
msort [x] = [x]
msort xs = merge (msort (leftHalf xs)) (msort (rightHalf xs))

leftHalf :: [a] -> [a]
leftHalf xs = take (length xs `div` 2) xs

rightHalf :: [a] -> [a]
rightHalf xs = drop (length xs `div` 2) xs

merge :: (Ord a) => [a] -> [a] -> [a]
merge [] [] = []
merge xs [] = xs
merge [] ys = ys
merge (x:xs) (y:ys)
  | x <= y    = x: merge xs (y:ys)
  | otherwise = y: merge (x:xs) ys
~~~

The `msort` function itself is easy enough to understand. Split the list in half, sort the halves individually, and then merge them.

But unlike quicksort, we have a few extra helper functions to accomplish the splitting and merging.

It turns out that the `leftHalf` and `rightHalf` functions are suboptimal in at least one respect: the `length` function scans the entire list to calculate the length.

Instead, a more efficient approach is to implement a `split` function. Here's one, courtesy of [Literate Programs](http://en.literateprograms.org/Merge_sort_(Haskell)):

~~~ haskell
msort :: (Ord a) => [a] -> [a]
msort [] = []
msort [x] = [x]
msort xs = merge (msort xs1) (msort xs2) where (xs1, xs2) = split xs

split :: (Ord a) => [a] -> ([a], [a])
split xs = go xs xs where
  go (x:xs) (_:_:zs) = (x:us, vs) where (us, vs) = go xs zs
  go    xs   _       = ([], xs)

-- merge same as above
~~~

It took a bit to wrap my head around what `split` is doing. To make things concrete, here's an example of its output:

~~~ haskell
ghci> split [3,1,4,5,1,3,4,2,4,5,6]
([3,1,4,5,1],[3,4,2,4,5,6])
~~~

The `split` function uses a tail-recursive worker loop, [conventionally called 'go'](http://stackoverflow.com/questions/5844653/haskell-why-the-convention-to-name-a-helper-function-go). We pass `xs` into `go` twice: the first for "slow runner" iteration and the second for "fast runner" iteration. When the fast runner runs out of elements, recursion bottoms out.

Now it's time to build the two sublists. The right half is easy: it's just whatever the slow runner hadn't gobbled at the time the fast runner finished. So we just return it as-is as we pop back up the stack.

But we have to build the left half. So we start with the empty list. As we pop up, we prepend the left half with the `x` the slow runner consumed at the given iteration. By the time we reach the top, we've prepended all such `x` and we have the split.

## Reflections on the above

I'm still new to functional programming, so I still have a beginner's understanding. But I often hear the contrast with imperative languages as being "what" (functional) vs. "how" (imperative). At some level this makes sense, as functional implementations suppress details that imperative implementations include. But not entirely. After all, different implementations lead to more or less efficient ways of performing the sort. Somehow the slow runner/fast runner feels very much like we're telling Haskell *how* to perform the computation. (Indeed, the [Literate Programs](http://en.literateprograms.org/Merge_sort_(Haskell)) page presents an alternative way to perform the split&mdash;one that's simpler, but that leads to unstable sorts.)

One potential beginner's confusion is to approach Haskell with a set theoretic, "function-as-graph" view of functions. On that view, one might assume that as long as you can specify the graph, then Haskell will magically figure out the best way to compute it. That's obviously not true, as the mergesort above shows. Instead Haskell is based on the lambda calculus, "function-as-rule" view. So while functional programming is more declarative than imperative languages, we still have to choose good rules if we want efficient computations.
