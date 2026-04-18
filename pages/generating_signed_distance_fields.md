title = Generating Signed Distance Fields
#---

# Introduction
Popularized by Valve, signed distance fields provide an efficient way to display text in games at an arbitrary resolution. In this four part series, I'll show how you can generate a texture atlas of signed distance fields from TrueType fonts as shown above.

# The algorithm
Let's start with the following pseudo code for generating our set of signed distance fields.

The formula for a quadratic Bézier curve is

$$B(t) = (1-t)^2P_0 + 2t(1-t)P_1 + t^2P_2$$

Here is a list
- A
- B
- C