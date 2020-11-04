-- ghosts.
--
-- @von_rostock
-- twitter.com/user/status/1322693583623884803
--
-- Ported by @eigenbahn


-- ------------------------------------------------------------------------
-- init

include('p8/lib/p8')

function init()
 screen.aa(0)
 screen.line_width(1)
 -- redraw()
end

local fps = 5000
re = metro.init()
re.time = 1.0 / fps
re.event = function()
 redraw()
end
re:start()


-- ------------------------------------------------------------------------
-- tweetcart

-- pal({-16,-14,-11,-12,4,-7,-2,9,10,-9,7},1)

cls(1)
s=sin

function redraw()
 -- ::_::
 r=s(t())
 u=rnd()
 v=rnd()
 c=cos
 a=u*.3+.6
 b=v*.3+.1
 z=2+s(a)*s(b)
 x=99*c(a)*s(b)
 y=(75+s(u*8)*8*s(v*2))*c(b)
 k=c(u/4+r/99)^2*7
 if((3-v*5>c(u) and .6<v)or(v<c(u*5)/1.8 and -c(u)>.5 and -s(u/2)/2<v)) then
  k=r+v*7+5
 end
 pset(64+(x/z)/1.5,32-((y/z)/2),k)
 -- goto _

 -- NB: added explicit flip
 flip()

end
