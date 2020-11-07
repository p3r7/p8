

-- -------------------------------------------------------------------------
-- STATE & MEMORY

curr_color = 0
curr_color_id = 0

curr_cursor_x = 0
curr_cursor_y = 0

curr_line_endpoint_x = nil
curr_line_endpoint_y = nil

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


-- -------------------------------------------------------------------------
-- TIME

curr_time = .0

time_fps = 10

clock.run(
 function()
  while curr_time < 32767 do
   local step_s = 1 / time_fps
   curr_time = curr_time + step_s
   clock.sleep(step_s)
  end

  curr_time = 32767
end)


function t()
 return curr_time
end


-- -------------------------------------------------------------------------
-- UTILS

function find_in_table(search_v, t)
 local index={}
 for k, v in pairs(t) do
  if v == search_v then
   return k
  end
 end
end

function range(a, b, step)
 if not b then
  b = a
  a = 1
 end
 step = step or 1
 local f =
  step > 0 and
  function(_, lastvalue)
   local nextvalue = lastvalue + step
   if nextvalue <= b then return nextvalue end
  end or
  step < 0 and
  function(_, lastvalue)
   local nextvalue = lastvalue + step
   if nextvalue >= b then return nextvalue end
  end or
  function(_, lastvalue) return lastvalue end
 return f, nil, a - step
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
 if x == 0 then
   return 0
 end
 if (not x) then
   x = 1
 end
 x = x * 100000
 x = math.random(x) / 100000
 return x
end

function srand(x)
 return math.randomseed(x)
end


-- -------------------------------------------------------------------------
-- MATH: TRIGONOMETRY

function cos(x)
 return math.cos(math.rad(x * 360))
end

function sin(x)
 return -math.sin(math.rad(x * 360))
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


-- -------------------------------------------------------------------------
-- SCREEN: BASICS

function cls()
 cursor(0, 0)
 screen.clear()
end

function flip()
 screen.update()
end


-- -------------------------------------------------------------------------
-- SCREEN: COLORS

default_palette_indices = {
 -- standard
 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
 -- secret
 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,
}
default_palette = {
 -- standard
 {   0,   0,   0 }, -- black          0
 {  29,  43,  83 }, -- dark-blue      3
 { 126,  37,  83 }, -- dark-purple    4
 {   0, 135,  81 }, -- dark-green     4
 { 171,  82,  54 }, -- brown          6
 {  95,  87,  79 }, -- dark-grey      5
 { 194, 195, 199 }, -- light-grey     11
 { 255, 241, 232 }, -- white          14
 { 255,   0,  77 }, -- red            6
 { 255, 163,   0 }, -- orange         8
 { 255, 236,  39 }, -- yellow         10
 {   0, 228,  54 }, -- green          5
 {  41, 173, 255 }, -- blue           9
 { 131, 118, 156 }, -- lavender       7
 { 255, 119, 168 }, -- pink           10
 { 255, 204, 170 }, -- light-peach    12
 -- secret
 {  41,  24,  20 }, -- darkest-grey   1
 {  17,  29,  53 }, -- darker-blue    1
 {  66,  33,  54 }, -- darker-purple  3
 {  18,  83,  89 }, -- blue-green     3
 { 116,  47,  41 }, -- dark-brown     4
 {  73,  51,  59 }, -- darker-grey    3
 { 162, 136, 121 }, -- medium-grey    8
 { 243, 239, 125 }, -- light-yellow   11
 { 190,  18,  80 }, -- dark-red       5
 { 255, 108,  36 }, -- dark-orange    7
 { 168, 231,  46 }, -- light-green    8
 { 0,   181,  67 }, -- medium-green   4
 { 6,    90, 181 }, -- medium-blue    5
 { 117,  70, 101 }, -- mauve          5
 { 255, 110,  89 }, -- dark peach     8
 { 255, 157, 129 }, -- peach          10
}
default_palette_transparency = {}
for i in range(#default_palette + 1) do
 default_palette_transparency[i] = false
end

curr_palette = default_palette
curr_palette_transparency = default_palette_transparency

function color(col)
 col = flr(col)
 -- NB: secret colors can only be accessed through `pal`
 curr_color_id = (col % 16)+1
 curr_color = rgb_to_greyscale(curr_palette[curr_color_id])
 screen.level(curr_color)
end

function color_maybe(col)
 if col then
  color(col)
 end
end

function pal(c0, c1, p)
 -- NB: use-case of p=0 is not clear to me

 if not c0 then
  curr_palette = default_palette
  palt() -- reset transparency
 else
  -- print("altering palette")
  c0_id = find_in_table(c0, default_palette_indices)
  c1_id = find_in_table(c1, default_palette_indices)
  curr_palette[c0_id] = curr_palette[c1_id]
 end
end

function palt(col, t)
 local col_id = find_in_table(col, default_palette_indices)
 if not col then
  curr_palette_transparency = default_palette_transparency
 else
  curr_palette_transparency[col_id] = t
 end
end

function is_color_transparent(col)
 local col_id = nil
 if col then
  col_id = find_in_table(col, default_palette_indices)
 else
  col_id = curr_color_id
 end
 return curr_palette_transparency[col_id]
end

function rgb_to_greyscale(rgb)
 local r = rgb[1]
 local g = rgb[2]
 local b = rgb[3]
 local grey_255 = (r + g + b) / 3
 local grey_16 = grey_255 * 15 / 255
 return flr(grey_16)
end


-- -------------------------------------------------------------------------
-- SCREEN: TEXT

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

 if not is_color_transparent() then
  screen.text(str)
 end

 curr_cursor_y = curr_cursor_y + 6
 if (curr_cursor_y + 6) >= 128 then
  curr_cursor_y = 0
 end
end


-- -------------------------------------------------------------------------
-- SCREEN: SHAPES

function pset(x, y, col)
 color_maybe(col)
 if is_color_transparent() then
  return
 end
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

 if is_color_transparent() then
  return
 end

 screen.move(x0, y0)
 screen.line(x1, y1)
 screen.stroke()

 set_current_line_endpoints(x1, y1)
end

function line_w_no_start(x1, y1, col)
 color_maybe(col)

 if is_color_transparent() then
  return
 end

 if curr_line_endpoint_x and curr_line_endpoint_y then
  screen.move(curr_line_endpoint_x, curr_line_endpoint_y)
  screen.line(x1, y1)
  screen.stroke()
 end

 set_current_line_endpoints(x1, y1)
end

function circ(x, y, r, col)
 color_maybe(col)
 if is_color_transparent() then
  return
 end
 screen.move(x + r, y)
 screen.circle(x, y, r)
 screen.stroke()
end

function circfill(x, y, r, col)
 color_maybe(col)
 if is_color_transparent() then
  return
 end
 screen.move(x + r, y)
 screen.circle(x, y, r)
 screen.fill()
end

function rect(x0, y0, x1, y1, col)
 color_maybe(col)
 if is_color_transparent() then
  return
 end
 screen.rect(x0, y0, (x1 - x0), (y1 - y0))
 screen.stroke()
end

function rectfill(x0, y0, x1, y1, col)
 color_maybe(col)
 if is_color_transparent() then
  return
 end
 screen.rect(x0, y0, (x1 - x0), (y1 - y0))
 screen.fill()
end
