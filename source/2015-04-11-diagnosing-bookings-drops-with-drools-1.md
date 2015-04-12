---
type: blog-post
title: Diagnosing Bookings Drops with Drools, Part 1
date: 2015-04-11
tags: java, rules, drools, operations, webops, logic programming, ai
published: true
---
_This is the first of two posts on diagnosing bookings drops with Drools. This one deals with drops due to holidays. The second post will treat drops due to technical issues._

I've been thinking of using a rules engine to help diagnose unexpected bookings drops. Rules are a good way to simplify reasoning about complex domains, and there are lots of different things that can lead to bookings drops. Examples include:

- Technical issues
- Holidays
- Major sporting events (Super Bowl, World Cup, etc.)
- Promotions
- A/B tests gone bad
- Moving from standard time to daylight saving time and vice versa

To make this work we'd need data ("facts" in [logic programming](http://en.wikipedia.org/wiki/Logic_programming) parlance) from a variety of sources and also rules. We would feed the diagnoses into downstream systems that decide what to do given a diagnosis.

I created a simple toy project called [Beedoc](https://github.com/williewheeler/beedoc) on GitHub. It uses the open source, Java-based [Drools](http://www.drools.org/) rules engine to generate diagnoses for incoming alerts. Drools is primarily a reactive, [forward chaining](http://en.wikipedia.org/wiki/Forward_chaining) system, but it also supports [backward chaining](http://en.wikipedia.org/wiki/Backward_chaining). Beedoc uses both inference styles, as we'll see.

# Diagnosing drops due to holidays

Holidays can obviously impact bookings. It may seem that it would be obvious when there's a bookings drop due to holidays, but this isn't necessarily true. For one thing, if your company does business globally, then it's easy to forget that it's Victoria Day in Canada or whatever. And in fact I know of a case where somebody in the US forgot that it was a major US holiday and started sounding the alarm when bookings were down.

It's super easy to do basic diagnoses for holiday-induced drops, so that's a nice starting point.

## Holiday rules

I have a couple of simple rules here: one for country-specific drops and another for regional drops. First here's the country rule:

~~~ java
rule "Diagnose country low bookings due to holiday"
when
  $c : Country()
  $a : CountryLowBookingsAlert(country == $c)
  $h : Holiday()
  $t : TodayIs(holiday == $h)
  $o : Observes(country == $c, holiday == $h)
then
  logger.info("Diagnosis for alert {}: holiday={}.", $a.getId(), $h.getName());
end
~~~

This one just says that if today is a holiday in the country that had the bookings drop, then that's the diagnosis. Or at least a candidate diagnosis.

Here's one that's slightly (but only slightly) more involved&mdash;this time for regional bookings drops:

~~~ java
rule "Diagnose region low bookings due to holiday"
when
  $r : Region()
  $a : RegionLowBookingsAlert(region == $r)
  $c : Country()
  $rc : RegionContains(region == $r, country == $c)
  $h : Holiday()
  $t : TodayIs(holiday == $h)
  $o : Observes(country == $c, holiday == $h)
then
  logger.info("Diagnosis for alert {}: holiday={} for country={}.", $a.getId(), $h.getName(), $c.getName());
end
~~~

These rules are just simple forward chaining. When certain facts appear in working memory&mdash; whether they're objects like alerts, regions, countries and holidays, predicates like `TodayIs`, or relationships like `RegionContains` or `Observes`&mdash;we use those to draw some further conclusion on the basis of the rule. In logic this is just repeated applications of [modus ponens](http://en.wikipedia.org/wiki/Modus_ponens); in logic programming it's called _forward chaining_. In this particular case we're simply logging the diagnosis rather than placing a new `Diagnosis` fact in working memory, but in real life we'd do the latter.

## Holiday facts

For facts, I just hardcoded a bunch. In a real system these would come from some business system or maybe file import.

~~~ java
// Geography
val na = new Region("na", "North America");
val eu = new Region("eu", "Europe");

val ca = new Country("ca", "Canada");
val de = new Country("de", "Germany");
val uk = new Country("uk", "UK");
val us = new Country("us", "US");

// Holidays
val christmas = new Holiday("christmas", "Christmas");
val indepDayUs = new Holiday("indep_day_us", "Independence Day (US)");
val thanksgivingUs = new Holiday("thanksgiving_us", "Thanksgiving (US)");
val victoriaDay = new Holiday("victoria_day", "Victoria Day (Canada)");

// Setup
ksession.insert(na);
ksession.insert(eu);

ksession.insert(ca);
ksession.insert(de);
ksession.insert(uk);
ksession.insert(us);

ksession.insert(christmas);
ksession.insert(indepDayUs);
ksession.insert(thanksgivingUs);
ksession.insert(victoriaDay);

ksession.insert(new RegionContains(eu, de));
ksession.insert(new RegionContains(eu, uk));
ksession.insert(new RegionContains(na, ca));
ksession.insert(new RegionContains(na, us));

ksession.insert(new Observes(ca, christmas));
ksession.insert(new Observes(ca, victoriaDay));
ksession.insert(new Observes(de, christmas));
ksession.insert(new Observes(uk, christmas));
ksession.insert(new Observes(us, christmas));
ksession.insert(new Observes(us, indepDayUs));
ksession.insert(new Observes(us, thanksgivingUs));
~~~

(The `val` stuff is from [Project Lombok](http://projectlombok.org/).)

Then I have a bunch of alerts:

~~~ java
alert(ksession, indepDayUs, new CountryLowBookingsAlert("C-1000", us));
alert(ksession, thanksgivingUs, new CountryLowBookingsAlert("C-1010", ca));
alert(ksession, thanksgivingUs, new CountryLowBookingsAlert("C-1015", us));
alert(ksession, null, new CountryLowBookingsAlert("C-1100", us));
alert(ksession, christmas, new RegionLowBookingsAlert("R-2000", eu));
alert(ksession, christmas, new RegionLowBookingsAlert("R-2010", na));
alert(ksession, indepDayUs, new RegionLowBookingsAlert("R-2020", na));
~~~

## Holiday execution

Here's the corresponding output, based on the fact, alerts and rules above:

~~~
==========
ALERT C-1000: Low bookings for country=US
Diagnosis for alert C-1000: holiday=Independence Day (US).
==========
ALERT C-1010: Low bookings for country=Canada
==========
ALERT C-1015: Low bookings for country=US
Diagnosis for alert C-1015: holiday=Thanksgiving (US).
==========
ALERT C-1100: Low bookings for country=US
==========
ALERT R-2000: Low bookings for region=Europe
Diagnosis for alert R-2000: holiday=Christmas for country=Germany.
Diagnosis for alert R-2000: holiday=Christmas for country=UK.
==========
ALERT R-2010: Low bookings for region=North America
Diagnosis for alert R-2010: holiday=Christmas for country=Canada.
Diagnosis for alert R-2010: holiday=Christmas for country=US.
==========
ALERT R-2020: Low bookings for region=North America
Diagnosis for alert R-2020: holiday=Independence Day (US) for country=US.
~~~

For alert C-1000 there was a single, unambiguous diagnosis. For C-1010 there wan't one since Canadians don't celebrate American Thanksgiving. For R-2000 and R-2010 there were multiple diagnoses since the regions involved have multiple countries that celebrate Christmas.

# Concluding remarks

The example we treated in this post was of course very basic. It mostly just shows how rules work. In the next post we'll diagnose bookings drops caused by technical issues, which is more interesting because it's more complex. It will also give us a chance to see backward chaining in action.
