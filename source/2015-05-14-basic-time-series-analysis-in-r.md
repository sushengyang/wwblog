---
type: blog-post
title: Basic Time Series Analysis in R
date: 2015-05-14
tags: r, math, statistics, time series analysis, programming
published: true
---
This is really just a set of personal notes for working with time series in R. But if it's useful to you, great.

I'm using the [xts](http://cran.r-project.org/web/packages/xts/index.html) package for time series data.

For now I'm just going to do the simple stuff (summary stats, plots, moving averages). In future posts I expect to add actual time series analyses.

## Loading a data set from a CSV file

This depends in part on the file format and also the date format. Suppose we have something like this:

~~~
timestamp,count
1429024200,70.92
1429025100,68.94
1429026000,81.72
1429026900,94.68

... snip ...
~~~

Here the timestamps are POSIX timestamps (seconds since Jan 1, 1970). So to read this into an xts object, we can do this:

~~~
> library(xts)
> toDate <- function(x) as.POSIXct(x, origin = "1970-01-01", tz = "GMT")
> tickets_df <- read.zoo("tickets.csv", header = TRUE, sep = ",", FUN = toDate)
> tickets <- as.xts(tickets_df)
~~~

Now that we have an xts object, we can do various analyses on it. Some of these are just summary statistics kinds of things and others are specifically time series analyses. As I mentioned above I'm sticking to the very basics here, so no autocorrelation, ARIMA, exponential smoothing, etc. for now. But xts supports that stuff.

## Getting the head and tail of the data set

We can use the `head` and `tail` commands for this. By default they return six rows each, but we can choose something different.

~~~
> head(tickets)
                      [,1]
2015-04-14 15:10:00  70.92
2015-04-14 15:25:00  68.94
2015-04-14 15:40:00  81.72
2015-04-14 15:55:00  94.68
2015-04-14 16:10:00  98.28
2015-04-14 16:25:00 107.46
~~~

~~~
> tail(tickets, 3)
                     [,1]
2015-04-15 14:10:00 41.76
2015-04-15 14:25:00 44.46
2015-04-15 14:40:00 46.08
~~~

## Computing summary statistics

Here are basic summary stats:

~~~
> summary(tickets)
     Index                        tickets      
 Min.   :2015-04-14 15:10:00   Min.   : 16.74  
 1st Qu.:2015-04-14 21:02:30   1st Qu.: 55.17  
 Median :2015-04-15 02:55:00   Median :134.28  
 Mean   :2015-04-15 02:55:00   Mean   :112.37  
 3rd Qu.:2015-04-15 08:47:30   3rd Qu.:161.28  
 Max.   :2015-04-15 14:40:00   Max.   :185.94  
~~~

Along similar lines, here's the [interquartile range (IQR)](http://en.wikipedia.org/wiki/Interquartile_range):

~~~
> IQR(tickets)
[1] 106.11
~~~

## Plotting a time series

~~~
> plot(tickets)
~~~

<a href="https://dl.dropboxusercontent.com/u/54053289/wwblog/tickets.png"><img class="figure img-responsive" src="https://dl.dropboxusercontent.com/u/54053289/wwblog/tickets.png" alt="Plotting a time series"></a>

## Computing a moving average

~~~
> tickets_ma <- rollmean(tickets, 7)
~~~

where 7 is the number of periods we've chosen.

<a href="https://dl.dropboxusercontent.com/u/54053289/wwblog/tickets_ma.png"><img class="figure img-responsive" src="https://dl.dropboxusercontent.com/u/54053289/wwblog/tickets_ma.png" alt="Smoothing via moving average"></a>

## Basic manipulations

We can perform arithmetic and other manipulations directly against the xts object. Here's an example:

~~~
> tickets_manip <- log(5 * tickets)
> plot(tickets_manip)
~~~

<a href="https://dl.dropboxusercontent.com/u/54053289/wwblog/tickets_manip.png"><img class="figure img-responsive" src="https://dl.dropboxusercontent.com/u/54053289/wwblog/tickets_manip.png" alt="Time series manipulation"></a>


