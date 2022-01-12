-- cube.
--
-- @neauoire
-- https://gist.github.com/neauoire/200d97396805dda71154
--
-- ported by @eigen


-- ------------------------------------------------------------------------
-- init

include('p8/lib/p8')

function init()
 screen.aa(1)
 screen.line_width(1)
end

local fps = 30
redraw_clock = clock.run(
  function()
    local step_s = 1 / fps
    while true do
      clock.sleep(step_s)
      redraw()
    end
end)

function cleanup()
  clock.cancel(redraw_clock)
end


-- ------------------------------------------------------------------------
-- tweetcart

angle = 0

-- line colors
c1 = 7
c2 = 8

r = 20
cx = 64
cy = 32

face_angle = 90

tilt_top = 0.5
tilt_bottom = 0.6

is_shift = false

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
  r = util.clamp(r + delta, 5, 30)
 elseif id == 2 then
  if is_shift then
   tilt_top = util.clamp(tilt_top + delta / 100, 0, 1)
  else
    face_angle = util.clamp(face_angle + delta, 10, 120)
  end
 elseif id == 3 then
  if is_shift then
   tilt_bottom = util.clamp(tilt_bottom + delta / 100, 0, 1)
  else
    face_angle = util.clamp(face_angle + delta, 10, 120)
  end
 end
end



function redraw()

 angle = angle + 2
 if angle > 360 then
  angle = 0
 end

 -- bounce
 -- tilt_top = (tilt_top + 0.05) % 1
 -- tilt_bottom = (tilt_bottom + 0.05) % 1

 cls()
 stx = {0,0,0,0}
 sty = {0,0,0,0}
 sbx = {0,0,0,0}
 sby = {0,0,0,0}

 i = 0
 while(i < 4) do
  angleoffset = (angle + (i*face_angle)) % 360
  a = angleoffset/360

  ltx = cx + r * cos(a)
  lty = cy + r * sin(a)
  lty = lty * tilt_top

  lbx = cx + r * cos(a)
  lby = cy + r * sin(a)
  lby = (lby * tilt_bottom) + r

  -- horizontal lines
  line(lbx,lby,ltx,lty,7)

  -- save coordinates
  stx[i] = ltx
  sty[i] = lty
  sbx[i] = lbx
  sby[i] = lby
  i = i + 1

 end

 -- draw back cross

 if angle < 135 or angle > 315 then
  line(stx[0],sty[0],sbx[1],sby[1],c2)
  line(sbx[0],sby[0],stx[1],sty[1],c2)
 end

 -- connect faces

 line(stx[0],sty[0],stx[1],sty[1],c1)
 line(stx[1],sty[1],stx[2],sty[2],c1)
 line(stx[2],sty[2],stx[3],sty[3],c1)
 line(stx[3],sty[3],stx[0],sty[0],c1)

 line(sbx[0],sby[0],sbx[1],sby[1],c1)
 line(sbx[1],sby[1],sbx[2],sby[2],c1)
 line(sbx[2],sby[2],sbx[3],sby[3],c1)
 line(sbx[3],sby[3],sbx[0],sby[0],c1)

 -- draw front cross

 if angle >= 135 and angle <= 315 then
  line(stx[0],sty[0],sbx[1],sby[1],c2)
  line(sbx[0],sby[0],stx[1],sty[1],c2)
 end

 -- p8print()

 flip()
end
