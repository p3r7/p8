-- manga-effect.
--
-- @kadoyan
-- twitter.com/user/status/1309354303933616131
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

function redraw()
 -- ::_::
 cls()
 l=flr(rnd(20))+30
 for i=0,l do r,s,c=rnd(20)+20,sin(i/l),cos(i/l)sx,sy,gx,gy=s*r+64,c*r+64,s*120,c*120line(sx,sy,64+gx,64+gy,7)
 end
 flip()
 -- goto _
end
