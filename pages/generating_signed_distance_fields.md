title = Generating Signed Distance Fields
#---

# Introduction
Popularized by Valve, signed distance fields provide an efficient way to display text in games at an arbitrary resolution. In this four part series, I'll show how you can generate a texture atlas of signed distance fields from TrueType fonts as shown above.

# The algorithm
Let's start with the following pseudo code for generating our set of signed distance fields.

The formula for a quadratic Bézier curve is

$$B(t) = (1-t)^2P_0 + 2t(1-t)P_1 + t^2P_2$$

where $t \in [0, 1]$ and $P_0(x_0, y_0), P_1(x_1, y_1)$ and $P_2(x_2, y_2)$ are the control points.

Given $t$, $B(t)$ will result in a point along the curve. Similar to the line segment, when
- $t = 0, B(t) = P_0$
- $t = 0.5, B(t) = P_1$
- $t = 1, B(t) = P_2$

Let's now define a new function given our point $p$.