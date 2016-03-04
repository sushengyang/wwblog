---
type: blog-post
title: Anomaly Detection Using STL
date: 2016-03-03
tags: statistics, time series analysis, stl, monitoring, operations, r, math, algorithms
published: true
---
In an [earlier post](/2015/05/16/monitoring-bookings-and-the-law-of-large-numbers/) I described a challenge attaching to monitoring bookings and other volatile time series; namely, that static thresholding often forces you to choose between false positives and false negatives.

This post describes a way to use dynamic thresholding to avoid that dilemma. We'll take a high-level look at an algorithm called STL, which stands for "Seasonal-Trend decomposition using Loess", and how to apply it to anomaly detection.

The basic idea is that if you have a time series with a regular pattern to it, you can run the series through the STL algorithm and identify the regular pattern from the time series. Everything left over is by definition "irregular", and anomaly detection amounts to deciding whether the irregularity is sufficiently large.

# An example: air passengers, 1949-1960

Let's run the algorithm on a modified version of the `AirPassengers` dataset in R, which gives counts for monthly airline passengers during the years 1949-1960. First, here's the unmodified time series:

~~~ R
> plot(AirPassengers)
~~~

<img class="figure img-responsive" src="/images/posts/anomaly-detection-using-stl/air-passengers.png" alt="Air passengers, 1949-1960">

There's clearly a regular pattern here, but there aren't any super-obvious drops in the series that might show up in an anomaly detection exercise. So we'll induce one.

~~~ R
> x <- AirPassengers
> length(x)
[1] 144
> x[40]
[1] 181
> x[40] = 150
> plot(x)
~~~

<img class="figure img-responsive" src="/images/posts/anomaly-detection-using-stl/air-passengers-modified.png" alt="Air passengers (modified), 1949-1960">

The drop is big enough that we'd expect an anomaly detector to surface it, but not so big that you'll automatically see it just by glancing at the chart. Now let's run it through STL:

~~~ R
> plot(stl(log(x), "periodic"))
~~~

<img class="figure img-responsive" src="/images/posts/anomaly-detection-using-stl/air-passengers-stl.png" alt="STL decomposition for air passengers (modified), 1949-1960">

Here's what's going on.

First, if you're paying attention, you'll notice that I ran STL not on _x_ itself, but on _log(x)_. There's a reason for that, but we'll ignore that momentarily.

The algorithm decomposes the series into three components: seasonal, trend and remainder. The _seasonal_ is the periodic component, the _trend_ is general up/down behavior, and the _remainder_ is what's left over. The seasonal and trend taken together form the "regular" part of the series, and thus the part that we want to discount during anomaly detection.

The remainder is essentially a normalized version of the original series, so this is what we monitor for anomalies. Remainder series drops are readily apparent. What counts as alert-worthy is up to the user, but the drop we induced in early 1952 would surely count. The drop in early 1960 is fairly sizable as well, and not at all obvious when you look at the original plot. Indeed you have to look pretty carefully at the original to see it.

<img class="figure img-responsive" src="/images/posts/anomaly-detection-using-stl/air-passengers-drop.png" alt="1960 drop">

# What about multiple seasonalities?

Some time series have more than one seasonality. For example, at Expedia (where I work), bookings time series have three seasonalities: daily, weekly and annual.

While there are procedures that generate decompositions with multiple seasonal components, STL doesn't do that. The highest frequency seasonality gets to be the seasonal component, and any lower frequency seasonalities get absorbed into the trend.

# Back to _log(x)_

Let's return to the question of why I decomposed _log(x)_ instead of decomposing _x_ directly. The reason has to do with the nature of the decomposition. STL decomposition is _additive_:

<p style="text-align:center;font-style:italic">x = s + t + r</p>

But some time series have _multiplicative_ decompositions:

<p style="text-align:center;font-style:italic">x = str</p>

This happens for example with sales data, where the amplitude of the seasonal component increases with increasing trend. This is in fact the hallmark of a multiplicative series, and the air passengers series exhibits this behavior. To deal with this, we log transform the original values, which carries us into addition-land, where we can do the STL decomposition. When we're done we can back-transform to get back to the original series, though we didn't do that step above.

# References

* [Forecasting: principles and practice, section 6.5](https://www.otexts.org/fpp/6/5)
* [R documentation for the STL function](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/stl.html)
