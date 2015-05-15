---
type: blog-post
title: Diagnosing Bookings Drops with Drools, Part 2
date: 2015-04-12
tags: java, rules, drools, operations, webops, logic programming, ai
published: false
---
_This post continues our exploration of using the Drools rule engine to diagnose bookings drops. The [first post](2015-04-11-diagnosing-bookings-drops-with-drools-1.html) treats the simple case of holiday-induced drops. In this post we'll look at the more interesting case of drops caused by technical issues._

One motivation for a rules-based approach to diagnostic problems is that it simplifies reasoning about complex domains. We can start with a partial knowledge of the domain, creating whatever rules we know at the time, and get useful diagnoses out of the system. As our knowledge deepens over time, we can incrementally add new rules and get more sophisticated diagnoses.

Technical systems are a rich source of complex behavior. In what follows we'll deal with a particular class of technical problems, which is unhealthy system dependencies. Here's how we'll do it:

1. When we get a bookings alert, rules will attempt to tie the problem to one or more frontend components, since bookings start there.
2. Once we identify the frontend components, we'll search their dependencies for problems.
3. If we find anything interesting we'll return that as a potential diagnosis.

Let's begin with an overview of our hypothetical system architecture.

## Hypothetical system architecture

<a href="https://dl.dropboxusercontent.com/u/54053289/wwblog/travel-arch.png"><img class="figure img-responsive" src="https://dl.dropboxusercontent.com/u/54053289/wwblog/travel-arch.png" alt="Hypothetical system architecture"></a>

(Click the diagram to enlarge.)

Here are the important points:

- Our system supports a global travel business, offering air and hotel products to North American and European markets (regions).
- North American and European instances of the system running in regional data centers serve their respective markets.
- Each system instance hosts country-specific points of sale (POS). The North American instance supports .ca and .com, while the European instance supports .de and .co.uk.
- The two air API instances depend on an external air [global distribution system (GDS)](http://en.wikipedia.org/wiki/Global_Distribution_System), and similarly, the two hotel API instances depend on an external hotel GDS.
- There's a shared checkout service running in the North American data center.

While this dramatically simplifies a real system, there's enough going on that there are several different ways things can fail. For example:

- If a single product's bookings in a single region are unhealthy, it could be the corresponding API or database.
- If all product bookings in a single region are unhealthy, it could be a the corresponding web UI or the data center itself. It could also be a connectivity issue between the web UI and the checkout service.
- If a single product's bookings are unhealthy across both regions, it could be an issue with the corresponding GDS.
- If all bookings are unhealthy, it could be a problem with the checkout service, a common mode failure (e.g. bad web UI release going out to both instances), simultaneous DDoS against both regions, and so on.

Clearly these don't exhaust the possibilities. But even this simple example illustrates the way in which different component failures can lead to different patterns of system failure. Our goal is to write rules to capture these relationships.

## A first pass at our diagnostic rules

A straightforward approach to implementing diagnostic rules is just to implement more or less specific diagnostic rules explicitly. For example, suppose we want to diagnose situations in which we have a region such that all and only points of sale in that region are down. (That is a fairly specific kind of situation that occurs from time to time.) We might formulate a rule along these lines:

~~~ java
rule "Region unhealthy"
salience 10
when
  $r : Region()
  $c : Component(code == $r.code + "_web_ui")
  forall( $pos : PointOfSale(region == $r)
          Alert(pos == $pos)
        )
  // Null-safe dereferencing operator
  forall( $a : Alert(pos!.region == $r) )
then
  logger.info("All and only POSes in region {} are unhealthy.", $r.getName());
  insert(new FindSystemDiagnosisGoal($c));
end
~~~

The left-hand side (LHS) specifies that the rule applies when there exists some region `$r` such that all and only points of sale in `$r` are alerting. If based on that trigger alone we knew what was wrong, then the RHS could simply insert the diagnosis. But even with our simple example there are multiple possible explanations, so we simply set a diagnostic goal to look for problems with the region's web UI or its dependencies. With this approach we'd define additional explicit rules to try to get to the bottom of things.

This approach has the benefit that the rules match how people might reason about the domain. When human experts perform a diagnosis it's usually based on knowledge of how certain specific parts of the system impact other specific parts of the system. So it's pretty easy to write rules in this style.

However another approach is possible. Instead of writing a variety of rules covering a variety of specific dependencies, we can treat our dependencies generically using a directed acyclic graph (DAG), and then write a small number of generic rules that know how to use the graph to diagnose faults. That's what we'll try next.

## Tracing component dependencies

To perform dependency analysis, our rules need a way to determine which components depend upon which other components, whether directly or indirectly. So we'll need to put dependency facts in working memory.

One way to do this would be to insert the entire [transitive closure](http://en.wikipedia.org/wiki/Transitive_closure) of dependency facts into working memory. That is, calculate all the indirect dependencies based on the direct ones, and then insert all dependencies (direct or not) into working memory.

The big problem with that approach is that there's a combinatorial explosion of dependencies for any realistic dependency graph.

So we'll take a different approach: we'll insert only the direct dependencies and establish a way of querying working memory as to whether component A is a dependency (direct or indirect) of component B. Here's the query:


