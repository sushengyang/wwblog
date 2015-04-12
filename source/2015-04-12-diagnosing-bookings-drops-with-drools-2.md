---
type: blog-post
title: Diagnosing Bookings Drops with Drools, Part 2
date: 2015-04-12
tags: java, rules, drools, operations, webops, logic programming, ai
published: false
---
TODO

# Diagnosing drops due to technical issues

There are all kinds of technical issues that can cause bookings issues. Maybe there was a new release that broke some critical JavaScript on the bookings path. Maybe the network is down. And so on.

In what follows we'll deal with a particular class of problems, which is when system dependencies are unavailable. Here's how we'll do it:

1. When we get a bookings alert, we'll check to see whether it's related to a particular geography, a particular product, or whether it seems to be more general. That will help steer the diagnosis toward specific system components.
2. Once we pick a system component to investigate, we'll query not only that component but also its dependencies&mdash;direct and indirect&mdash;for their health.
3. If we find components having problems, we'll return that information in a diagnosis.

## System dependency rules

## System dependency query

## System dependency facts

## System dependency execution

