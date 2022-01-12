-- gravity.
--
-- @jamesedge
-- https://www.lexaloffle.com/bbs/?tid=36182
--
-- Ported by @eigen


-- ------------------------------------------------------------------------
-- init

include('p8/lib/p8')
include('p8/lib/physics')

function init()
  screen.aa(1)
  screen.line_width(1)

  init_scene()
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
-- cart

function init_scene()
  ppx_init(5)
  shape = px_convex(10, 10)
  for _,c in pairs(shape) do
    if c[1]>0 then c[1], c[2] = 0.5*c[1]+20, 0.5*c[2] end
  end

  for i=1,5 do
    body = ppx.body(i*20, rnd(64)-32, 1, shape, -3, 0)
    body.a = rnd(TWOPI)
  end
  ppx.boundary(64, 64, 0, -1)
  ppx.boundary(0, 64, 1, 0)
  ppx.boundary(127, 64, -1, 0)
end

function redraw()
  screen.clear()

  ppx.update()
  for i,body in pairs(ppx.bodies) do
    draw_body(body, (i+6)%15+1)
  end

  screen.update()
end
