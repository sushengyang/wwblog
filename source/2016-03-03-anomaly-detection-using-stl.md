---
type: blog-post
title: Anomaly Detection Using STL
date: 2016-03-03
tags: statistics, time series analysis, stl, monitoring, operations, r, math, algorithms
published: true
---
In an [earlier post](/2015/05/16/monitoring-bookings-and-the-law-of-large-numbers/) I described a challenge attaching to monitoring bookings and other volatile time series; namely, that static thresholding often forces you to choose between false positives and false negatives.

This post describes a way to use dynamic thresholding to avoid that dilemma. We'll take a high-level look at an algorithm called STL, which stands for "Seasonal-Trend decomposition using Loess", and how to apply it to anomaly detection.

The basic idea is that if you have a time series with a regular pattern to it, you can run the series through the STL algorithm and isolate the regular pattern. Everything left over is by definition "irregular", and anomaly detection amounts to deciding whether the irregularity is sufficiently large.

# An example: air passengers, 1949-1960

Let's run the algorithm on a modified version of the `AirPassengers` dataset in R, which gives counts for monthly airline passengers during the years 1949-1960. First, here's the unmodified time series:

~~~ R
plot(AirPassengers)
~~~

<img class="figure img-responsive" src="/images/posts/anomaly-detection-using-stl/air-passengers.png" alt="Air passengers, 1949-1960">

There's clearly a regular pattern here, but there aren't any super-obvious drops in the series that might show up in an anomaly detection exercise. So we'll induce one.

~~~ R
y <- AirPassengers
y[40] = 150
plot(y)
~~~

<img class="figure img-responsive" src="/images/posts/anomaly-detection-using-stl/air-passengers-modified.png" alt="Air passengers (modified), 1949-1960">

The drop is big enough that we'd expect an anomaly detector to surface it, but not so big that you'll automatically see it just by glancing at the chart. Now let's run it through STL:

~~~ R
fit <- stl(log(y), "periodic")
plot(fit)
~~~

<img class="figure img-responsive" src="/images/posts/anomaly-detection-using-stl/air-passengers-stl.png" alt="STL decomposition for air passengers (modified), 1949-1960">

Here's what's going on.

First, if you're paying attention, you'll notice that I ran STL not on _y_ itself, but on _log(y)_. There's a reason for that, but we'll come back to it.

The algorithm decomposes the series into three components: seasonal, trend and remainder. The _seasonal_ is the periodic component, the _trend_ is general up/down behavior, and the _remainder_ is what's left over. The seasonal and trend taken together form the "regular" part of the series, and thus the part that we want to discount during anomaly detection.

The remainder is essentially a normalized version of the original series, so this is what we monitor for anomalies. Remainder series drops are readily apparent. What counts as alert-worthy is up to the user, but the drop we induced in early 1952 would likely count.

Though here we're just going with default parameters, [STL supports a fair number of parameters](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/stl.html). They allow you to control things like the number of observations per period, the smoothing behavior responsible for separating the seasonal and trend components, the "robustness" (i.e., outlier insensitivity) of the fitted model and so forth. Most of these parameters require some understanding of how the underlying algorithm works. I won't go into that here since this is an overview.

Here's some code to display the actuals against the thresholds. Install the ggplot2 R package if you don't already have it.

~~~ R
log.seasonal <- fit$time.series[, "seasonal"]
log.trend <- fit$time.series[, "trend"]
log.expected <- log.seasonal + log.trend
library(ggplot2)
df <- data.frame(x = seq(1, 144), y = y)
band <- data.frame(x = df$x, ymin=exp(log.expected - 0.08), ymax=exp(log.expected + 0.08))
all.data <- merge(df, band, by.x='x')
ggplot(all.data, aes(x=x, y=y)) +
  theme_bw() +
  geom_ribbon(aes(x=x, ymin=ymin, ymax=ymax), fill="gray", alpha=0.5) +
  geom_line(linetype="dashed")
~~~

<img class="figure img-responsive" src="/images/posts/anomaly-detection-using-stl/with-band.png" alt="With band">

Once again, the eagle-eyed among you might notice the back-transform via _exp()_. We can discuss that now.

# Why the log- and back-transforms?

Not all decompositions involve log transforms, but this one does. The reason has to do with the nature of the decomposition. STL decomposition is always _additive_:

<p style="text-align:center;font-style:italic">y = s + t + r</p>

But for some time series, a _multiplicative_ decomposition is a better fit:

<p style="text-align:center;font-style:italic">y = str</p>

This happens for example with sales data, where the amplitude of the seasonal component increases with increasing trend. This is in fact the hallmark of a multiplicative series, and the air passengers series exhibits this behavior. To deal with this, we log transform the original values, which carries us into addition-land, where we can do the STL decomposition. When we're done we back-transform to get back to the original series.

# What about multiple seasonalities?

Some time series have more than one seasonality. For example, at Expedia (where I work), bookings time series have three seasonalities: daily, weekly and annual.

While there are procedures that generate decompositions with multiple seasonal components, STL doesn't do that. The highest frequency seasonality gets to be the seasonal component, and any lower frequency seasonalities get absorbed into the trend.

# Update: stlplus

I recently learned of an enhanced R-based implementation of the algorithm, by Ryan Hafen, called [stlplus](https://github.com/hafen/stlplus). New features include:

* Handles gaps in the time series by interpolation.
* Loess smoother supports quadratic local regression (original implementation supported only degrees 0 and 1).
* Can produce additional frequency components beyond the seasonal and trend components.
* Applies a "blending" procedure to reduce error at the time series endpoints.
* Has various plots to support diagnostics.

# References

* [Hyndman, Rob J. & Athanasopoulos, George. Forecasting: principles and practice, section 6.5](https://www.otexts.org/fpp/6/5)
* [Cleveland, R. B., Cleveland, W. S., McRae, J. E., & Terpenning, I. (1990). STL: A seasonal-trend decomposition procedure based on loess. *Journal of Official Statistics*, 6(1), 3-73.](http://cs.wellesley.edu/~cs315/Papers/stl%20statistical%20model.pdf)
* [Hafen, R. P. "Local regression models: Advancements, applications, and new methods." (2010).](http://ml.stat.purdue.edu/hafen/preprints/Hafen_thesis.pdf)
* [R documentation for the STL function](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/stl.html)
* [stlplus (GitHub repo)](https://github.com/hafen/stlplus)
