---
type: blog-post
title: Python Turtle Graphics
date: 2016-02-22
tags: python, turtle graphics
published: true
---
These are just some simple Python turtle graphics programs for my kids to goof
around with. I may add more programs to this post over time.

## Squarish.py

<img class="figure img-responsive" src="https://db.tt/UhRmwTQv" alt="Squarish.py">

~~~ python
import turtle

colors = ["red", "yellow", "green", "blue"]
numColors = len(colors)

turtle.bgcolor("black")
t = turtle.Pen()

for i in range(200):
  t.pencolor(colors[i % numColors])
  t.forward(i)
  t.left(88)
~~~

## RotatingSquares.py

<img class="figure img-responsive" src="https://db.tt/QwND6Qa6" alt="RotatingSquares.py">

~~~ python
import turtle

colors = ["red", "orange", "yellow", "green", "blue", "purple"]
numColors = len(colors)

turtle.bgcolor("black")
t = turtle.Pen()
t.width(2)

for i in range(360):
  t.pencolor(colors[i % numColors])
  t.forward(200)
  t.right(92)
~~~
