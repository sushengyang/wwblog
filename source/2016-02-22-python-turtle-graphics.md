---
type: blog-post
title: Python Turtle Graphics
date: 2016-02-22
tags: python, turtle graphics
published: false
---
These are just some simple Python turtle graphics programs for my kids to goof
around with. I may add more programs to this post over time.

## RotatingSquares.py

<img class="figure img-responsive" src="https://dl.dropboxusercontent.com/u/54053289/wwblog/turtle-graphics/rotating-squares.png" alt="RotatingSquares.py">

~~~ python
import turtle

colors = ["red", "orange", "yellow", "green", "blue", "purple"]
numColors = len(colors)

wn = turtle.Screen()
turtle.bgcolor("black")
t = turtle.Pen()
t.width(2)

for i in range(360):
  t.pencolor(colors[i % numColors])
  t.forward(200)
  t.right(92)

wn.mainloop()
~~~
