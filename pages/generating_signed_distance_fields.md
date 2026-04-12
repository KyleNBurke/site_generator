title = Generating Signed Distance Fields
###

# Generating signed distance fields from TrueType fonts

## Introduction
Popularized by Valve, signed distance fields provide an efficient way to display text in games at an arbitrary resolution. In this four part series, I'll show how you can generate a texture atlas of signed distance fields from TrueType fonts as shown above.

The technique in the [original Valve paper](https://steamcdn-a.akamaihd.net/apps/valve/2007/SIGGRAPH2007_AlphaTestedMagnification.pdf) is to take a high resolution input bitmap, create a corresponding high resolution signed distance field, then downscale that to the desired final resolution. I'll show an alternative approach that uses only the desired resolution and produces exact distances in a reasonable amount of time. The trade off is the need to use a lot of math, including some calculus.

While this series is tailored towards TrueType fonts, the algorithm can be used to generate signed distance fields from a vector defined shape given it's closed and made up of straight lines or quadratic Bézier curves. Rust will be my language of choice throughout the code examples and I won't be explaining what a signed distance field actually is and the related spread factor, that is not the focus of this series.

Here's the breakdown: in part one, we'll look at the algorithm and setup the code for parts two and three which will call into a function for calculating the distance and a function for calculating the sign of that distance. The distance calculation is covered in part two and the calculation for sign of the distance is covered in part three. Part four will cover generating the texture atlas from the set of distance fields.

## The algorithm
Let's start with the following pseudo code for generating our set of signed distance fields.
