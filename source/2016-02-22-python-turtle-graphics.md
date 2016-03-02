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

<img class="figure img-responsive" src="/images/posts/python-turtle-graphics/squarish.png" alt="Squarish.py">

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

<img class="figure img-responsive" src="/images/posts/python-turtle-graphics/rotating-squares.png" alt="RotatingSquares.py">

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

## Bamboo.py

<img class="figure img-responsive" src="/images/posts/python-turtle-graphics/bamboo.png" alt="Bamboo.py">

~~~ python
import turtle

turtle.bgcolor("black")
t = turtle.Pen()
t.pencolor("green")
t.left(90)

height = 5
width = 2

for i in range(10):
  k = 10 - i
  t.forward(k * height)
  t.right(90)
  t.forward(k * width)
  t.right(90)
  t.forward(k * height)
  t.right(90)
  t.forward(k * width)

  t.right(90)
  t.forward(k * height)
  t.left(5)
~~~

## Shell.py

<img class="figure img-responsive" src="/images/posts/python-turtle-graphics/shell.png" alt="Shell.py">

~~~ python
import turtle

turtle.bgcolor("black")
t = turtle.Pen()
t.pencolor("yellow")

for i in range(200):
  t.circle(i)
  t.left(3)
~~~

## Stars.py

This one's from Nicu Parente, with minor modifications by me. Thanks Nicu.

<img class="figure img-responsive" src="/images/posts/python-turtle-graphics/stars.png" alt="Shell.py">

~~~ python
import turtle

colors = ["red", "yellow", "green", "blue"]
numColors = len(colors)

turtle.bgcolor("black")
t = turtle.Pen()
t.width(2)

position = 1
while (position < 10):
  t.pencolor(colors[(position - 1) % numColors])
  for i in range(5):
    t.forward(10*position)
    t.left(72)
    t.forward(10*position)
    t.right(144)
  position += 1
  t.left(92)
  t.penup()
  t.forward(90)
  t.pendown()
~~~
