---
type: blog-post
title: Monitoring Bookings and the Law of Large Numbers
date: 2015-05-16
tags: math, statistics, monitoring, operations, webops
published: true
---
When monitoring bookings, one common approach is to use historical levels as a baseline, and then alert if the current level is _x_% lower than the historical, where _x_ is a static value that tries to strike a balance between capturing as many problems as possible and avoiding alert spam.

You may have noticed that sometimes, there's just no good threshold. Whatever number you choose, it either misses too many real events or else generates too much noise.

Why isn't there a good number?

## Coin flips

Let's start by looking at something simple: coin flips.

Suppose that somebody hands you a quarter and tells you to decide whether it's a fair coin. So you flip the coin six times: `H T T H H H`. In other words, 67% heads and 33% tails. Is it fair?

Pretty clearly it's impossible to draw a strong conclusion here. Both fair and unfair coins can generate runs like that.

Now suppose we repeat the experiment, but this time we flip the coin 1,000 times, getting 667 heads and 333 tails.

This is definitely a biased coin, as a fair coin can't produce a sample like that. Not only that, but we're pretty confident that the probability of heads is very close to 2/3.

In each case we got 67% heads and 33% tails, but in the first we couldn't draw any conclusion about bias at all (let alone the degree of bias), whereas in the second case the bias and its degree are clear as day. So what's the difference?

The difference is the sample size. There's something in statistics called the [law of large numbers](http://en.wikipedia.org/wiki/Law_of_large_numbers), which basically says that the sample mean converges to the population mean as the sample gets bigger. Here we're dealing with sample proportions rather than sample means (i.e., proportion of heads in the sample), but for that we have [Borel's law of large numbers](http://en.wikipedia.org/wiki/Law_of_large_numbers#Borel.27s_law_of_large_numbers): the proportion of an event (like getting heads) converges to the true proportion with increasing sample size.

With small sample sizes, the law of large numbers hasn't kicked in, so the sample proportion isn't a reliable estimate of the population proportion. Seeing four heads out of six flips doesn't mean much. On the other hand, if we see 667 heads and 333 tails, there's no way a fair coin will behave in that way, and that's what the law says.

A coin flip is a special case of something called a [binomial trial](http://en.wikipedia.org/wiki/Bernoulli_trial) (a.k.a. Bernoulli trial), and a series of such trials is called a _binomial experiment_. In a binomial experiment, there are _n_ trials. Any given trial has two possible outcomes, traditionally called "success" and "failure", along with a probability _p_ of success.

Using the language of binomial experiments, our first experiment was _n_ = 6, and we wanted to evaluate the claim that _p_ = 0.5. In the second experiment we had _n_ = 1,000 and we wanted to evaluate the same claim about _p_.

Now let's bring this back to bookings.

## Applying the law of large numbers to bookings

We can think of bookings as binomial experiments. During any given window of time, we have a certain number of visitors to the site, and they either book (success) or not (failure). The probability of a booking, known in marketing-speak as a _conversion rate_, is generally far lower than 0.5; _p_ = 0.01 would be far more typical. But we're still talking about a binomial experiment.

Now imagine that our company offers a number of different products via different points of sale (e.g., .ca, .com, .co.uk, etc.) and different channels. Imagine further that traffic patterns change depending on the hour of the day, the day of the week, and maybe even the time of the month or the time of the year.

It shouldn't be that hard to imagine these things since they are completely typical.

We want to monitor bookings for all the possible combinations, or at least the important ones. To keep it simple, let's say we want to monitor our main .com site during the day when things are busy and during the night when they aren't.

During the day, there's a lot of traffic, so our bookings binomial experiments have large _n_. Assuming traffic volumes and conversion rates haven't changed dramatically over the past few weeks, the law of large numbers tells us that corresponding historical bookings should be very close, percentage-wise, to what we should be seeing currently.

At night, there's not that much traffic, and so now we're dealing with small _n_. The law of large numbers can't help us anymore. The historical bookings we have are analogous to seeing four heads out of six coin flips: they don't tell us much about what we should be seeing now.

(We're just using day and night as an example. The same remarks apply to weekdays vs. weekends, popular products vs. less popular products, big points of sale vs. small ones, etc.)

Now it should be clear why no single static threshold can correctly solve the false positive/negative dilemma. In high volume contexts, we want narrower thresholds (e.g., 10%), because deltas between the historical and current proportions are more signal than noise, thanks to the law of large numbers. In low volume contexts, we need wide thresholds&mdash;these could easily be 50% or larger&mdash;in order to reduce false alarms.

No static threshold can be both narrow and wide at the same time, and that's what creates the dilemma.
