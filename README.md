# p8

Compatibility layer to run [_pico-8_](https://www.lexaloffle.com/pico-8.php) scripts on the [_monome norns_](https://monome.org/docs/norns/).

This is not suitable for running full-fledged carts (with sprites, sound...), targeting instead [_tweetcart_](https://twitter.com/hashtag/tweetcart?lang=en) (code fitting in a tweet).


## Why?

Both platform share similar goals: build a community around sharing small apps written in Lua.

_pico-8_ is centered around games, _norns_ around music-making apps.

The _pico-8_ community provided some pretty crazy examples of what can be done with basic functions and I thought that one community could benefit from the efforts of the other.

The aim is not to have it embedded systematically in a _norns_ app but instead to quickly steal animation ideas from _tweetcart_ and see how they get rendered on the _norns_ display.


## How?

By defining pico-8 API functions from norns-compatible Lua code ([code](./lib/p8.lua)).

To compare them:
- [_pico-8_ API reference](https://pico-8.fandom.com/wiki/APIReference)
- [_norns_ API reference](https://monome.org/docs/norns/api/) (look especially at the [screen](https://monome.org/docs/norns/api/classes/screen.html) API)

Their display APIs are pretty close to one another.

On the contrary, _pico-8's_ trigonometric functions behave quite differently from the standard Lua `math` lib.


## Examples

[ghosts.lua](ghosts.lua) ([original tweetcart](https://twitter.com/user/status/1322164958008905728) by [@Alexis_Lessard](https://twitter.com/Alexis_Lessard)).

![norns_p8_ghosts](https://www.eigenbahn.com/assets/gif/norns_p8_ghosts.gif)

[manga_effect.lua](manga_effect.lua) ([original tweetcart](https://twitter.com/user/status/1319781601425952768) by [@kadoyan](https://twitter.com/kadoyan)).

![norns_p8_manga-effect](https://www.eigenbahn.com/assets/gif/norns_p8_manga-effect.gif)

[tree.lua](tree.lua) ([original tweetcart](https://twitter.com/user/status/1319781601425952768) by [@Alexis_Lessard](https://twitter.com/Alexis_Lessard)).

![norns_p8_tree](https://www.eigenbahn.com/assets/gif/norns_p8_tree.gif)

[pumpkin.lua](tree.lua) ([original tweetcart](https://twitter.com/user/status/1322693583623884803) by [@von_rostock](https://twitter.com/von_rostock)).

![norns_p8_pumpkin](https://www.eigenbahn.com/assets/gif/norns_p8_pumpkin.gif)


## Usage

#### General

Most _pico-8_ _tweetcarts_ define a combination of `goto` and `flip`.

It needs to be slightly adapted:

 - the label / `goto` block needs to be moved to a function (typically `redraw`)
 - this function needs to be called from a `metro` object

See the [Examples](#examples) for concrete use-cases.


#### print

_pico-8's_ `print` allows printing on the screen.

_norns_ is not happy with having the standard `print` function redefined.

That's why _pico-8's_ version got renamed `p8print`.


#### Special _pico-8_ Lua syntax

_pico-8's_ Lua differs a bit from standard Lua.

It notably provides additional constructs such as `+=` and `-=` to increase / decrease values. These instructions should be converted for _norns_ to interpret them.

```lua
-- valid pico-8 Lua
t += 1

-- valid Lua
t = t + 1
```

There is also the `@<address>` shorthand for `peek` that would need to be converted to an explicit `peek` call.


## Completeness

Not all of [_pico-8_ APIs](https://pico-8.fandom.com/wiki/APIReference) will get implemented.

The following are not yet here but are the next one on the list:
- `fillp` (patterned fill)
- `tline` (textured line)
- map and table APIs

These are interesting but seem difficult to implement fully with current _norns_ APIs:
- `pget`
- `clip`
- `camera`

These might get implemented in a very loose way:
- `fset` / `fget`
- sprite sheet fns: `sset` / `sget`, `spr`, `sspr`

Current implementation of `print` (`p8print`) does not handle `\n` and screen scroll on end of framebuffer.

Current implementation of `peek` and `poke` only support interacting with the current color and current text cursor position.

Current implementation of `pal` doesn't honor the `p` parameter.
