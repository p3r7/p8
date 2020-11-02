

-- -------------------------------------------------------------------------
-- STATE

curr_color = 6

curr_cursor_x = 0
curr_cursor_y = 0

curr_line_endpoint_x = nil
curr_line_endpoint_y = nil

palette_indices = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}
palette = {
 {   0,   0,   0 }, -- black
 {  29,  43,  83 }, -- dark-blue
 { 126,  37,  83 }, -- dark-purple
 {   0, 135,  81 }, -- dark-green
 { 171,  82,  54 }, -- brown
 {  95,  87,  79 }, -- dark-grey
 { 194, 195, 199 }, -- light-grey
 { 255, 241, 232 }, -- white
 { 255,   0,  77 }, -- red
 { 255, 163,   0 }, -- orange
 { 255, 236,  39 }, -- yellow
 {   0, 228,  54 }, -- green
 {  41, 173, 255 }, -- blue
 { 131, 118, 156 }, -- lavender
 { 255, 119, 168 }, -- pink
 { 255, 204, 170 }, -- light-peach
}

secret_palette_indices = {128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143}
secret_palette = {
 {  41,  24,  20 }, -- darkest-grey
 {  17,  29,  53 }, -- darker-blue
 {  66,  33,  54 }, -- darker-purple
 {  18,  83,  89 }, -- blue-green
 { 116,  47,  41 }, -- dark-brown
 {  73,  51,  59 }, -- darker-grey
 { 162, 136, 121 }, -- medium-grey
 { 243, 239, 125 }, -- light-yellow
 { 190,  18,  80 }, -- dark-red
 { 255, 108,  36 }, -- dark-orange
 { 168, 231,  46 }, -- light-green
 { 0,   181,  67 }, -- medium-green
 { 6,    90, 181 }, -- medium-blue
 { 117,  70, 101 }, -- mauve
 { 255, 110,  89 }, -- dark peach
 { 255, 157, 129 }, -- peach
}


function set_current_line_endpoints(x, y)
  curr_line_endpoint_x = x
  curr_line_endpoint_y = y
end

function invalidate_current_line_endpoints()
  curr_line_endpoint_x = nil
  curr_line_endpoint_y = nil
end

function peek(addr)
 if addr == 0x5f25 then
  return curr_color
 elseif addr == 0x5f26 then
  return curr_cursor_x
 elseif addr == 0x5f27 then
  return curr_cursor_y
 end
end

function poke(addr, val)
 if addr == 0x5f25 then
  color(val)
 end
end


-- -- -------------------------------------------------------------------------
-- -- BASIC

function cls()
 cursor(0, 0)
 screen.clear()
end

function flip()
 screen.update()
end


-- -------------------------------------------------------------------------
-- MATH: BINARY OPS

function band(x, y)
  return x & y
end

function bnot(x)
  return ~x
end

function bor(x, y)
  return x | y
end

function bxor(x, y)
  return x ~ y
end

function shl(num, bits)
  return num << bits
end

function shr(num, bits)
  return num >> bits
end


-- -------------------------------------------------------------------------
-- MATH: RANDOMNESS

function rnd(x)
  return math.random(x)
end

function srand(x)
  return math.randomseed(x)
end


-- -------------------------------------------------------------------------
-- MATH: BASICS

function sgn(x)
  if x < 0 then
    return -1
  else
    return 1
  end
end

function mid(x, y, z)
 mx = max(max(x, y), z)
 mn = min(min(x ,y), z)
 return x ~ y ~ z ~ mx ~ mn
end

function min(x, y)
  return math.min(x, y)
end

function max(x, y)
  return math.max(x, y)
end

function abs(x)
  return math.abs(x)
end

function sqrt(x)
  return math.sqrt(x)
end

function flr(x)
 return math.floor(x)
end


-- -------------------------------------------------------------------------
-- MATH: TIRGONOMETRIC

function cos(x)
 return math.cos(math.rad(x * 360))
end

function sin(x)
 return math.sin(math.rad(x * 360))
end

-- this seems to do the work
-- mostly stolen from https://www.lexaloffle.com/bbs/?pid=10287#p
function atan2(dx, dy)
 local q = 0.125
 local a = 0
 local ay = abs(dy)
 if ay == 0 and dx ==0 then
  ay = 0.001
 end
 if dx >= 0 then
  local r = (dx - ay) / (dx + ay)
  a = q - r*q
  else
   local r = (dx + ay) / (ay - dx)
   a = q*3 - r*q
  end
  if dy > 0 then
   a = -a
  end
  return a
end

-- failed attempt
-- function atan2(dx, dy)
--  return 1 - math.atan2(dx, dy) / (2 * math.pi)
-- end


-- -- -------------------------------------------------------------------------
-- -- COLOR

function color(col)
 curr_color = col
 screen.level(curr_color)
end

function color_maybe(col)
 if col then
  color(col)
 end
end

function rgb_to_greyscale(rgb)
 local r = rgb[1]
 local g = rgb[2]
 local b = rgb[3]
 local grey_255 = (r + g + b) / 3
 local grey_16 = grey_255 * 15 / 255
 return grey_16
end

-- -- -------------------------------------------------------------------------
-- -- TEXT

function cursor(x, y, col)
 color_maybe(col)
 if x then
  curr_cursor_x = x
 end
 if y then
  curr_cursor_y = y
 end
 screen.move(curr_cursor_x, curr_cursor_y)
end

-- NB: print is too tricky to override
function p8print(str, x, y, col)
 cursor(x, y, col)

 -- TODO: handle \n and whole screen scroll on value wrap
 screen.text(str)

 curr_cursor_y = curr_cursor_y + 6
 if (curr_cursor_y + 6) >= 128 then
  curr_cursor_y = 0
 end
end


-- -- -------------------------------------------------------------------------
-- -- SHAPES

function pset(x, y, col)
 color_maybe(col)
 screen.pixel(x, y)
 screen.fill()
end

function line(a1, a2, a3, a4, a5)
 if not a1 then
  invalidate_current_line_endpoints()
 elseif not a2 then
  color_maybe(a1)
  invalidate_current_line_endpoints()
 elseif not a4 then
  line_w_no_start(a1, a2, a3)
 else
  line_w_start(a1, a2, a3, a4, a5)
 end
end

function line_w_start(x0, y0, x1, y1, col)
 color_maybe(col)

 screen.move(x0, y0)
 screen.line(x1, y1)
 screen.stroke()

 set_current_line_endpoints(x1, y1)
end

function line_w_no_start(x1, y1, col)
 color_maybe(col)

 if curr_line_endpoint_x and curr_line_endpoint_y then
  screen.move(curr_line_endpoint_x, curr_line_endpoint_y)
  screen.line(x1, y1)
  screen.stroke()
 end

 set_current_line_endpoints(x1, y1)
end

function circ_impl(x, y, r, col)
 color_maybe(col)
 screen.move(x + r, y)
 screen.circle(x, y, r)
end

function circ(x, y, r, col)
 circ_impl(x, y, r, col)
 screen.stroke()
end

function circfill(x, y, r, col)
 circ_impl(x, y, r, col)
 screen.fill()
end


function rect(x0, y0, x1, y1, col)
 color_maybe(col)
 screen.rect(x0, y0, (x1 - x0), (y1 - y0))
 screen.stroke()
end

function rectfill(x0, y0, x1, y1, col)
 color_maybe(col)
 screen.rect(x0, y0, (x1 - x0), (y1 - y0))
 screen.fill()
end
