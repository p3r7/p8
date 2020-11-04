-- trees.
--
-- @Alexis_Lessard
-- twitter.com/user/status/1319781601425952768
--
-- Ported by @eigen


-- ------------------------------------------------------------------------
-- init

include('p8/lib/p8')

function init()
 screen.aa(1)
 screen.line_width(1)
end

local fps = 10
re = metro.init()
re.time = 1.0 / fps
re.event = function()
 redraw()
end
re:start()


-- ------------------------------------------------------------------------
-- tweetcart

function j(l,b,a)
 x,y=b[1],b[2]
 if(l>1)then
  n={x+a,y-l}line(x,y,n[1],n[2],c[min(3,flr(l/6))+1])j(l/1.38,n,a-4)n={b[1]+a,b[2]-l}j(l/1.42,n,a+4)
 end
end

-- NB: screen size adjustment
-- t,c,b=0,{11,3,4,132},{64,112}
t,c,b=0,{11,3,4,132},{64,90}


function redraw()
 -- ::z::
 q,w=sin(t),cos(t)cls()
 line(64,128,64,112,132)
 j(20+q*3,b,-3+q)j(22+q*4,b,3+w)
 flip()
 t = t + .01
 -- goto z
end
