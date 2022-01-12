-- confetti.
--
-- @von_rostock
-- twitter.com/user/status/1324156597569048578
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

p=0
q=0
s=0
-- pal({-15,-14,-11,-10,-1,9,10,-9},1)
r=rnd


function redraw()
  -- ::_::
  if(s<.2) then
    srand(t())
    b=r()
    s=16
  end

  s=s*.9
  k=s*cos(b)
  l=s*sin(b)
  p=p+k
  q=q+l
  cls()
  srand()
  for d=1,9,.1 do
    x=(r(146)+p*d/8)%146-9
    y=(r(146)+q*d/8)%146-9
    a=d+t()*(1+r())/2
    u=d*cos(a)
    v=d*sin(a)
    line(x-u,y-v,x+k,y+l,d)
    line(x+u,y+v)
  end
  flip()
  -- goto _
end
