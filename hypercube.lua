-- hypercube.
--
-- @Ivoah
-- https://gist.github.com/Ivoah/477775d13e142b2c89ba
--
-- Ported by @eigen


-- ------------------------------------------------------------------------
-- init

include('p8/lib/p8')

function init()
 screen.aa(1)
 screen.line_width(1)
end

local fps = 30
re = metro.init()
re.time = 1.0 / fps
re.event = function()
 redraw()
end
re:start()


-- ------------------------------------------------------------------------
-- cart init

cube = {{{-1,-1,-1}, -- points
    {-1,-1,1},
    {1,-1,1},
    {1,-1,-1},
    {-1,1,-1},
    {-1,1,1},
    {1,1,1},
    {1,1,-1},
    {-0.5,-0.5,-0.5}, -- inside
    {-0.5,-0.5,0.5},
    {0.5,-0.5,0.5},
    {0.5,-0.5,-0.5},
    {-0.5,0.5,-0.5},
    {-0.5,0.5,0.5},
    {0.5,0.5,0.5},
    {0.5,0.5,-0.5}},
  {{1,2}, -- lines
    {2,3},
    {3,4},
    {4,1},
    {5,6},
    {6,7},
    {7,8},
    {8,5},
    {1,5},
    {2,6},
    {3,7},
    {4,8},
    {8+1,8+2}, -- inside
    {8+2,8+3},
    {8+3,8+4},
    {8+4,8+1},
    {8+5,8+6},
    {8+6,8+7},
    {8+7,8+8},
    {8+8,8+5},
    {8+1,8+5},
    {8+2,8+6},
    {8+3,8+7},
    {8+4,8+8},
    {1,9},--
    {2,10},
    {3,11},
    {4,12},
    {5,13},
    {6,14},
    {7,15},
    {8,16}}}

-- init
cam = {0,0,-4} -- Initilise the camera position
mult = 64 -- View multiplier
a = flr(rnd(3))+1 -- Angle for random rotation
t = flr(rnd(50))+25 -- Time until next angle change

is_shift = false


-- ------------------------------------------------------------------------
-- USER INPUT

function key(id,state)
  if id == 1 then
    if state == 0 then
      is_shift = false
    else
      is_shift = true
    end
  end
end


function enc(id,delta)
  if id == 1 then
    cam[3] = cam[3] + delta / 5
  elseif id == 2 then
    if is_shift then
      -- tilt_top = util.clamp(tilt_top + delta / 100, 0, 1)
    else
      cam[1] = cam[1] + delta / 10
    end
 elseif id == 3 then
  if is_shift then
    -- tilt_bottom = util.clamp(tilt_bottom + delta / 100, 0, 1)
  else
    cam[2] = cam[2] + delta / 10
  end
 end
end


-- ------------------------------------------------------------------------
-- MAIN LOOP

function redraw()
  t = t - 1 -- Decrease time until next angle change
  if t <= 0 then -- If t is 0 then change the random angle and restart the timer
    t = flr(rnd(50))+25 -- Restart timer
    a = flr(rnd(3))+1 -- Update angle
  end
  cube = rotate_shape(cube,a,0.01)


  cls()
  draw_shape(cube)
  flip()
end


-- ------------------------------------------------------------------------
-- 3D LIB

function draw_shape(s,c)
  for l in all(s[2]) do -- For each line in the shape...
    draw_line(s[1][l[1]], s[1][l[2]], c) -- Draw the line
  end
end

function draw_line(p1,p2,c)
  x0, y0 = project(p1) -- Get the 2d location of the 3d points...
  x1, y1 = project(p2)
  line(x0, y0, x1, y1, c or 11) -- And draw a line between them
end

function draw_point(p,c)
  x, y = project(p) -- Get the 2d location of the 3d point...
  pset(x, y, c or 11) -- And draw the point
end

function project(p)
  x = (p[1]-cam[1])*mult/(p[3]-cam[3]) + 127/2 -- Calculate x and center it
  y = -(p[2]-cam[2])*mult/(p[3]-cam[3]) + 64/2 -- Calculate y and center it
  return x, y -- Return the two points
end

function translate_shape(s,t)
  ns = {{},s[2]} -- Copy the shape, but zero out the points and keep the lines
  for p in all(s[1]) do -- For each point in the original shape...
    add(ns[1],{p[1]+t[1],p[2]+t[2],p[3]+t[3]}) -- Add the displacement to the point and add it to our new shape
  end
  return ns -- Return the new shape
end

function rotate_shape(s,a,r)
  ns = {{},s[2]} -- Copy the shape, but zero out the points and keep the lines
  for p in all(s[1]) do -- For each point in the original shape...
    add(ns[1], rotate_point(p,a,r)) -- Rotate the point and add it to the new shape
  end
  return ns -- Return the new shape
end

function rotate_point(p,a,r)
  -- Figure out which axis we're rotating on
  if a==1 then
    x,y,z = 3,2,1
  elseif a==2 then
    x,y,z = 1,3,2
  elseif a==3 then
    x,y,z = 1,2,3
  end
  _x = cos(r)*(p[x]) - sin(r) * (p[y]) -- Calculate the new x location
  _y = sin(r)*(p[x]) + cos(r) * (p[y]) -- Calculate the new y location
  np = {} -- Make new point and assign the new x and y to the correct axes
  np[x] = _x
  np[y] = _y
  np[z] = p[z]
  return np -- Return new point
end
