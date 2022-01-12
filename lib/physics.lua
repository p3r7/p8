-- physics lib
--
-- @jamesedge
--
-- https://www.lexaloffle.com/bbs/?tid=36182
-- https://ubm-twvideo01.s3.amazonaws.com/o1/vault/gdc09/slides/04-GDC09_Catto_Erin_Solver.pdf

include('p8/lib/p8')


-- ------------------------------------------------------------------------

ROOT2 = 1.41421356237
PI    = 3.14159265359
TWOPI = 6.28318530718

function round(x)
  return (x<0.0) and math.floor(x-0.5) or math.floor(x+0.5)
end


function cosine(a) return cos(a/TWOPI) end
function sine(a) return sin(-a/TWOPI) end
function tangent(a) return sine(a)/cosine(a) end
function cotangent(a) return cosine(a)/sine(a) end

function v2dot(ux, uy, vx, vy)
  return ux*vx+uy*vy
end

function v2crs(ux, uy, vx, vy)
  return ux*vy-uy*vx
end

function v2len(vx, vy)
  return sqrt(vx*vx+vy*vy)
end

function v2nrm(x, y)
  -- print("X="..x..", Y="..y)
  -- print("X="..abs(x)..", Y="..max(abs(y)))
  -- local maxv = max(abs(x), max(abs(y)))
  local maxv = max(abs(x), abs(y))

  if maxv == 0x0 then return x, y, 0
  elseif maxv > 0x7f then return v2nrm(shr(x, 4), shr(y, 4))
  elseif maxv < 0x0.02 then return v2nrm(shl(x, 4), shl(y, 4)) end

  local len = v2len(x, y)
  return x/len, y/len, len
end

TINY          = 0.001

POINT         = 0 -- 0b00
EDGE          = 1 -- 0b01
POINT_TO_EDGE = 1 -- 0b01
EDGE_TO_POINT = 2 -- 0b10
EDGE_TO_EDGE  = 3 -- 0b11

BODY_NODE     = 0 -- 0b00
BRANCH_NODE   = 1 -- 0b01

BOUNDARY      = 0 -- 0b00
COLLISION     = 1 -- 0b01
JOINT         = 2 -- 0b10

ppx = nil -- state object

-- aabb object for broad-phase collisions
function aabb(x1, y1, x2, y2)
  local self = { x1=x1, y1=y1, x2=x2, y2=y2 }

  self.overlaps = function(box)
    return self.x2>=box.x1 and self.x1<=box.x2 and
      self.y2>=box.y1 and self.y1<=box.y2
  end

  self.contains = function(box)
    return box.x1>=self.x1 and box.y1>=self.y1 and
      box.x2<=self.x2 and box.y2<=self.y2
  end

  return self
end

-- aabb tree for fast collision searches
function aabb_tree()
  local contents = {}
  local self = {
    root=nil, -- tree root node
    contents=contents -- table of bodies in the tree
  }

  function extents(node) -- updates the size of branch nodes
    local box, pad = node.box, ppx.scale*4
    if node.type == BRANCH_NODE then
      local x1L, y1L, x2L, y2L = extents(node.left)
      local x1R, y1R, x2R, y2R = extents(node.right)
      box.x1, box.y1, box.x2, box.y2 =
        x1L<x1R and x1L or x1R, y1L<y1R and y1L or y1R,
        x2L>x2R and x2L or x2R, y2L>y2R and y2L or y2R
      return box.x1, box.y1, box.x2, box.y2
    else
      -- pad lead nodes to prevent continuous reinsertion
      return box.x1+min(node.vx<0 and node.vx/6 or 0, -pad),
        box.y1+min(node.vy<0 and node.vy/6 or 0, -pad),
        box.x2+max(node.vx>0 and node.vx/6 or 0, pad),
        box.y2+max(node.vy>0 and node.vy/6 or 0, pad)
    end
  end

  self.add = function(body) -- add a body to the aabb tree
    local root, box = self.root, body.box
    if contents[body.id] then
      if body.parent ~= nil then
        if body.parent.box.contains(box) then return body end
        self.remove(body)
      end
    end
    if not(root) then self.root = body
    else
      local sibling = root
      while sibling.type==BRANCH_NODE do
        sibling.id = (body.id>sibling.id and body.id or sibling.id)
        local boxL, boxR = sibling.left.box, sibling.right.box
        if ((max(boxL.x2, box.x2)-min(boxL.x1, box.x1))*
          (max(boxL.y2, box.y2)-min(boxL.y1, box.y1)))<
          ((max(boxR.x2, box.x2)-min(boxR.x1, box.x1))*
            (max(boxR.y2, box.y2)-min(boxR.y1, box.y1))) then sibling = sibling.left
        else sibling = sibling.right end
      end

      local parent = sibling.parent
      local branch = {
        type=BRANCH_NODE,
        id=(body.id>sibling.id and body.id or sibling.id),
        parent=parent,
        left=sibling, right=body,
        box=aabb(0, 0, 0, 0)
      }
      sibling.parent, body.parent = branch, branch

      if parent then
        if parent.left==sibling then parent.left = branch
        else parent.right = branch end
      else self.root = branch end

      while sibling.parent~=nil and not(sibling.parent.box.contains(body.box)) do
        sibling = sibling.parent
      end
      extents(sibling)
    end
    contents[body.id] = body
    return body
  end

  self.remove = function(body) -- remove a body from the aabb tree
    if contents[body.id] then
      local parent = body.parent
      if parent then
        local sibling = (parent.left==body) and parent.right or parent.left
        sibling.parent = parent.parent
        if sibling.parent == nil then self.root = sibling
        else
          if sibling.parent.left == parent then sibling.parent.left = sibling
          else sibling.parent.right = sibling end

          while sibling.parent~=nil and sibling.parent.id==body.id do
            sibling = sibling.parent
            sibling.id = (sibling.left.id>sibling.right.id and sibling.left.id or sibling.right.id)
          end
        end
      else self.root = nil end
      contents[body.id] = nil
    end
  end

  self.query = function(body) -- search aabb tree for all collisions with body
    if not(self.root) then return {} end
    local boxA, results, head = body.box, {}, { node=self.root, next=nil }

    while head do
      local node, boxB = head.node, head.node.box
      head = head.next

      if node ~= body and boxA.overlaps(boxB) then
        if node.type==BRANCH_NODE then
          head = { node=node.left, next=head }
          head = { node=node.right, next=head }
        else
          local rec = body.collides(node)
          if rec then results[#results+1] = rec end
        end
      end
    end
    return results
  end

  self.collisions = function(node, bodies) -- search the aabb tree for all collisions
    node = node or self.root
    bodies = bodies or self.contents
    local results = {}

    if node==nil then return results end

    if node.type==BRANCH_NODE then
      local left, right = node.left, node.right
      local boxL, boxR, bodiesL, bodiesR = left.box, right.box, {}, {}
      for id,body in pairs(bodies) do
        if left.id>id and boxL.overlaps(body.box) then bodiesL[id] = body end
        if right.id>id and boxR.overlaps(body.box) then bodiesR[id] = body end
      end
      local resultsL, resultsR = self.collisions(left, bodiesL),
        self.collisions(right, bodiesR)
      results = resultsL
      for _,rec in pairs(resultsR) do results[#results+1] = rec end
    else
      for _,body in pairs(bodies) do
        local rec = body.collides(node)
        if rec then results[#results+1] = rec end
      end
    end
    return results
  end

  self.update = function() -- update the aabb tree
    for _,body in pairs(contents) do self.add(body) end
    extents(self.root)
  end

  return self
end

-- the physics state object
function ppx_init(unit, slop)
  unit = unit or 4
  slop = slop or 0
  local bodies, bounds, joints, springs, constraints, tree =
    {}, {}, {}, {}, {}, aabb_tree()
  local state = {
    t=0, -- current simulation time
    fsteps=2, -- timesteps per frame
    isteps=4, -- steps for velocity correction
    beta=0.5, -- % of constraints to be solved per frame
    bodies=bodies, -- table of rigid bodies in the system
    unit=unit, -- physical units in pixels per metre
    scale=1/unit, -- scale for converting into metres
    ox=64, oy=64, -- origin in screen coordinates
    gx=0.0, gy=unit*9.81, -- gravity in x,y direction
    slop=slop/unit, -- slop for collision detection
    bounds=bounds, -- boundary constraints
    joints=joints, -- joint constraints
    springs=springs, -- spring forces
    collisions={}, -- collisions from the last frame
    tree=tree -- aabb tree
  }

  state.body = function(x, y, mass, coords, cmx, cmy)
    cmx, cmy = cmx or 0, cmy or 0
    local anchors, box, size, normals, points =
      { { x=0, y=0, tx=0, ty=0 } }, aabb(0, 0, 0, 0), #coords, {}, {}
    local ox, oy, scale = state.ox, state.oy, state.scale

    -- calculate body geometry
    for i,c in pairs(coords) do
      points[i] = { x=scale*(c[1]-cmx), y=scale*(c[2]-cmy), tx=0, ty=0, left=nil, right=nil }
    end

    for i=1,size do
      local p1, p2 = points[i], points[i%size+1]
      local nx, ny = v2nrm(p2.y-p1.y, -(p2.x-p1.x))
      local nrm = { p1=p1, p2=p2, x=nx, y=ny, tx=nx, ty=ny, maxp=p1.x*nx+p1.y*ny }
      normals[#normals+1] = nrm
      p1.left, p2.right = nrm, nrm
    end

    -- calculate moment of inertia
    local pmass, moi = mass/size, 0
    for _,pnt in pairs(points) do
      moi = moi + (pnt.x*pnt.x + pnt.y*pnt.y)*pmass
    end

    local obj = {
      type=BODY_NODE, -- indicates a leaf node
      id=#bodies+1, -- body index
      alive=true,
      layer=1, -- which layer the body is in (0 indicates cannot be collided with)
      collision=255, -- which layers does the body collide with (0 indicates it does not collide with other bodies)
      x=state.scale*(x-state.ox), y=state.scale*(y-state.oy), a=0, -- position/orientation
      fx=0, fy=0, fa=0, -- external forces
      g=1, -- 1 indicates subject to gravity
      dofx=1, dofy=1, dofa=1, -- degrees of freedom, 0 indicates no movement
      vx=0, vy=0, va=0, -- velocity/angular velocity
      frict=0.5, rest=0.5, -- friction/restitution
      mass=mass, imass=(mass==0) and 0 or 1/mass, -- mass
      moi=moi, imoi=(moi==0) and 0 or 1/moi, -- moment of inertia
      points=points, normals=normals, -- geometry of the body
      anchors=anchors, -- anchors for joints
      box=box, -- aabb for broad phase collision
      parent=nil -- parent in aabb tree
    }

    -- performs a SAT test between two bodies, returns a collision record for the
    -- minimum separating axis
    function sat(bodyA, bodyB)
      local slop, type, dist, nx, ny, rAx, rAy, rBx, rBy =
        state.slop, 0, 0x7fff, 0, 0, 0, 0, 0, 0

      for _,nrm in pairs(bodyB.normals) do
        local minp, minpt = 0x7fff, nil
        for _,pnt in pairs(bodyA.points) do
          local p = nrm.tx*pnt.tx+nrm.ty*pnt.ty
          if p<minp then minp, minpt = p, pnt end
        end
        if nrm.maxp<(minp+slop) then return nil end

        local d = nrm.maxp-minp
        if d<dist then
          type, dist, nx, ny = POINT_TO_EDGE, d, nrm.tx, nrm.ty
          local left, right = minpt.left, minpt.right
          local ldt, rdt = left.tx*nrm.tx+left.ty*nrm.ty,
            right.tx*nrm.tx+right.ty*nrm.ty
          if abs(1+ldt)<TINY or abs(1+rdt)<TINY then
            type = EDGE_TO_EDGE
            local par, ex, ey = ldt<rdt and left or right, -nrm.y, nrm.x
            local p1, p2, p3, p4 =
              ex*(nrm.p1.tx-minpt.tx)+ey*(nrm.p1.ty-minpt.ty),
              ex*(nrm.p2.tx-minpt.tx)+ey*(nrm.p2.ty-minpt.ty),
              ex*(par.p1.tx-minpt.tx)+ey*(par.p1.ty-minpt.ty),
              ex*(par.p2.tx-minpt.tx)+ey*(par.p2.ty-minpt.ty)
            local minn, maxn, minp, maxp =
              p1<p2 and p1 or p2,
              p1>p2 and p1 or p2,
              p3<p4 and p2 or p4,
              p3>p4 and p3 or p4

            local alpha
            if minp>minn and maxp<maxn then alpha = 0.5*(minp+maxp)
            elseif minn>minp and maxn<maxp then alpha = 0.5*(minn+maxn)
            elseif minp>minn then alpha = 0.5*(minp+maxn)
            else alpha = 0.5*(maxp+minn) end

            rAx, rAy = minpt.tx+alpha*ex, minpt.ty+alpha*ey
            rBx, rBy = rAx+nrm.tx*d, rAy+nrm.ty*d
          else
            rAx, rAy = minpt.tx, minpt.ty
            rBx, rBy = rAx+nrm.tx*d, rAy+nrm.ty*d
          end
        end
      end

      return { type=type, dist=dist-slop, nx=nx, ny=ny, rAx=rAx, rAy=rAy, rBx=rBx, rBy=rBy }
    end

    -- determines if there is a collision with the specified body
    obj.collides = function(body)
      local bodyA, bodyB = obj, body
      if band(bodyA.collision, bodyB.layer)>0 and -- must be from a collidable layer
        bodyA.box.overlaps(bodyB.box) then -- perform broad phase test
        local recAB, recBA = sat(bodyA, bodyB), sat(bodyB, bodyA) -- perform narrow phase test
        if recAB and recBA then
          if recAB.dist<recBA.dist then
            return { bodyA=bodyA, bodyB=bodyB, dist=recAB.dist, nx=recAB.nx, ny=recAB.ny,
                     rAx=recAB.rAx, rAy=recAB.rAy, rBx=recAB.rBx, rBy=recAB.rBy }
          else
            return { bodyA=bodyA, bodyB=bodyB, dist=recBA.dist, nx=-recBA.nx, ny=-recBA.ny,
                     rAx=recBA.rBx, rAy=recBA.rBy, rBx=recBA.rAx, rBy=recBA.rAy }
          end
        end
      end
      return nil
    end

    -- transforms the body (points, normals, anchors), updates aabb
    obj.transform = function()
      local x, y, a = obj.x, obj.y, obj.a
      local ca, sa = cosine(a), sine(a)
      box.x1, box.y1, box.x2, box.y2 = 0x7fff, 0x7fff, 0x8000, 0x8000
      for _,pnt in pairs(points) do
        pnt.tx, pnt.ty = pnt.x*ca-pnt.y*sa+x, pnt.x*sa+pnt.y*ca+y
        box.x1, box.y1, box.x2, box.y2 =
          box.x1<pnt.tx and box.x1 or pnt.tx,
          box.y1<pnt.ty and box.y1 or pnt.ty,
          box.x2>pnt.tx and box.x2 or pnt.tx,
          box.y2>pnt.ty and box.y2 or pnt.ty
      end
      for _,anc in pairs(anchors) do
        anc.tx, anc.ty = anc.x*ca-anc.y*sa+x, anc.x*sa+anc.y*ca+y
      end
      for _,nrm in pairs(normals) do
        nrm.tx, nrm.ty = nrm.x*ca-nrm.y*sa, nrm.x*sa+nrm.y*ca
        nrm.maxp = nrm.p1.tx*nrm.tx+nrm.p1.ty*nrm.ty
      end
      return obj
    end

    -- add an anchor to the body
    obj.anchor = function(offx, offy)
      local a = { x=offx*state.scale, y=offy*state.scale, tx=0, ty=0 }
      anchors[#anchors+1] = a
      obj.transform()
      return a
    end

    tree.add(obj.transform())
    bodies[#bodies+1] = obj
    return obj
  end

  -- add a boundary, acts like a rigid body with no degrees of freedom
  state.boundary = function(x, y, nx, ny)
    local ox, oy, scale = state.ox, state.oy, state.scale
    x, y = (x-ox)*scale, (y-oy)*scale
    local b = {
      x=x, y=y,
      dofx=0, dofy=0, dofa=0,
      vx=0, vy=0, va=0,
      frict=1, rest=0,
      mass=0, imass=0,
      moi=0, imoi=0,
      maxp=x*nx+y*ny, nx=nx, ny=ny
    }
    bounds[#bounds+1] = b
    return b
  end

  -- add a joint between two bodies
  state.joint = function(bodyA, idxA, bodyB, idxB)
    local jt = {
      active=true,
      bodyA=bodyA, bodyB=bodyB,
      idxA=idxA, idxB=idxB,
      anchorA=bodyA.anchors[idxA],
      anchorB=bodyB.anchors[idxB]
    }
    joints[#joints+1] = jt
    return jt
  end

  state.spring = function(bodyA, idxA, bodyB, idxB, k, damp)
    local sp = {
      active=true,
      bodyA=bodyA, bodyB=bodyB,
      idxA=idxA, idxB=idxB,
      anchorA=bodyA.anchors[idxA],
      anchorB=bodyB.anchors[idxB],
      k=k, damp=damp, rlen=0
    }
    local dx, dy = sp.anchorA.tx-sp.anchorB.tx,
      sp.anchorA.ty-sp.anchorB.ty
    sp.rlen = sqrt(dx*dx+dy*dy)
    springs[#springs+1] = sp
    return sp
  end

  -- calculate parameters for solving a collision constraint
  function collision(bodyA, bodyB, dist, nx, ny, rAx, rAy, rBx, rBy, beta)
    local xA, yA, vxA, vyA, vaA, imassA, imoiA, dofxA, dofyA, dofaA,
      xB, yB, vxB, vyB, vaB, imassB, imoiB, dofxB, dofyB, dofaB =
      bodyA.x, bodyA.y, bodyA.vx, bodyA.vy, bodyA.va,
      bodyA.imass, bodyA.imoi, bodyA.dofx, bodyA.dofy, bodyA.dofa,
      bodyB.x, bodyB.y, bodyB.vx, bodyB.vy, bodyB.va,
      bodyB.imass, bodyB.imoi, bodyB.dofx, bodyB.dofy, bodyB.dofa
    local rAcAx, rAcAy, rBcBx, rBcBy = rAx-xA, rAy-yA, rBx-xB, rBy-yB
    local rvx, rvy = vxA-rAcAy*vaA-vxB-rBcBy*vaB, vyA+rAcAx*vaA-vyB-rBcBx*vaB
    local tx, ty = -ny, nx
    if tx*rvx+ty*rvy<0 then tx, ty = -tx, -ty end

    local Jn = { dofxA*nx, dofyA*ny, dofaA*(rAcAx*ny-rAcAy*nx),
                   -dofxB*nx, -dofyB*ny, -dofaB*(rBcBx*ny-rBcBy*nx) }
    if (Jn[1]*vxA+Jn[2]*vyA+Jn[3]*vaA+Jn[4]*vxB+Jn[5]*vyB+Jn[6]*vaB)<0 then
      local JM, b = Jn[1]*imassA*Jn[1]+Jn[2]*imassA*Jn[2]+Jn[3]*imoiA*Jn[3]+
        Jn[4]*imassB*Jn[4]+Jn[5]*imassB*Jn[5]+Jn[6]*imoiB*Jn[6],
        -beta*dist + 0.5*(bodyA.rest+bodyB.rest)*min(0, rvx*nx+rvy*ny)

      local Jt = { dofxA*tx, dofyA*ty, dofaA*(rAcAx*ty-rAcAy*tx),
                     -dofxB*tx, -dofyB*ty, -dofaB*(rBcBx*ty-rBcBy*tx) }

      JtM = Jt[1]*imassA*Jt[1]+Jt[2]*imassA*Jt[2]+Jt[3]*imoiA*Jt[3]+
        Jt[4]*imassB*Jt[4]+Jt[5]*imassB*Jt[5]+Jt[6]*imoiB*Jt[6]

      return {
        type=COLLISION,
        bodyA=bodyA, bodyB=bodyB,
        nx=nx, ny=ny, tx=tx, ty=ty,
        rAx=rAx, rAy=rAy,
        rBx=rBx, rBy=rBy,
        active=true,
        inequality=true,
        J=Jn, b=b, JM=JM,
        lambda=0,
        Jt=Jt, JtM=JtM,
        f=0.5*(bodyA.frict+bodyB.frict),
        lambdat=0
      }
    end
    return nil
  end

  -- handle boundary constraints
  -- project each object onto the boundary, if there is penetration handle
  -- as though there is a collision with an object of infinite mass
  function handle_bounds(beta)
    for _,b in pairs(bounds) do
      local maxp, nx, ny = b.maxp, b.nx, b.ny
      for _,body in pairs(bodies) do
        local minp, minpt = 0x7fff, nil
        for _,pnt in pairs(body.points) do
          local p = nx*pnt.tx+ny*pnt.ty
          if p<minp then minp, minpt = p, pnt end
        end
        local dist = maxp-minp
        if dist>0 then
          local left, right, px, py = minpt.left, minpt.right, minpt.tx, minpt.ty
          if abs(1+left.tx*nx+left.ty*ny)<TINY then
            px, py = 0.5*(left.p1.tx+left.p2.tx), 0.5*(left.p1.ty+left.p2.ty)
          elseif abs(1+right.tx*nx+right.ty*ny)<TINY then
            px, py = 0.5*(right.p1.tx+right.p2.tx), 0.5*(right.p1.ty+right.p2.ty)
          end

          local c = collision(body, b, dist, nx, ny, px, py, px+nx*dist, py+ny*dist, beta)
          if c then constraints[#constraints+1] = c end
        end
      end
    end
  end

  -- handle joint constraints
  function handle_joints(beta)
    for i,jt in pairs(joints) do
      local bodyA, bodyB = jt.bodyA, jt.bodyB
      local pA, pB = jt.anchorA, jt.anchorB
      local imassA, imoiA, dofxA, dofyA, dofaA, imassB, imoiB, dofxB, dofyB, dofaB =
        bodyA.imass, bodyA.imoi, bodyA.dofx, bodyA.dofy, bodyA.dofa,
        bodyB.imass, bodyB.imoi, bodyB.dofx, bodyB.dofy, bodyB.dofa

      local J = { dofxA*2*(pA.tx-pB.tx),
                  dofyA*2*(pA.ty-pB.ty),
                    -dofaA*2*v2crs(pA.tx-pB.tx, pA.ty-pB.ty, pA.tx-bodyA.x, pA.ty-bodyA.y),
                  dofxB*2*(pB.tx-pA.tx),
                  dofyB*2*(pB.ty-pA.ty),
                  dofaB*2*v2crs(pA.tx-pB.tx, pA.ty-pB.ty, pB.tx-bodyB.x, pB.ty-bodyB.y) }

      local b = beta*((pA.tx-pB.tx)*(pA.tx-pB.tx)+(pA.ty-pB.ty)*(pA.ty-pB.ty))
      local JM = J[1]*imassA*J[1]+J[2]*imassA*J[2]+J[3]*imoiA*J[3]+
        J[4]*imassB*J[4]+J[5]*imassB*J[5]+J[6]*imoiB*J[6]

      constraints[#constraints+1] = {
        type=JOINT,
        bodyA=bodyA, bodyB=bodyB,
        active=true,
        inequality=false,
        J=J, b=b, JM=JM,
        lambda=0
      }
    end
  end

  -- handle body-body collisions
  function handle_collisions(beta)
    state.collisions = tree.collisions()
    for _,rec in pairs(state.collisions) do
      constraints[#constraints+1] =
        collision(rec.bodyA, rec.bodyB, rec.dist, rec.nx, rec.ny,
                  rec.rAx, rec.rAy, rec.rBx, rec.rBy, beta)
    end
  end

  -- apply spring forces
  function apply_springs()
    for _,spring in pairs(springs) do
      local bodyA, bodyB, pA, pB =
        spring.bodyA, spring.bodyB,
        spring.anchorA, spring.anchorB
      local rAx, rAy, rBx, rBy =
        pA.tx-bodyA.x, pA.ty-bodyA.y,
        pB.tx-bodyB.x, pB.ty-bodyB.y
      local dvx, dvy, dx, dy =
        bodyA.vx-bodyB.vx, bodyA.vy-bodyB.vy,
        pA.tx-pB.tx, pA.ty-pB.ty
      local len = sqrt(dx*dx+dy*dy)
      dx = dx / len
      dy = dy / len
      local f = spring.k*(len-spring.rlen)
      local fx, fy = -dx*f-dvx*spring.damp,
        -dy*f-dvy*spring.damp
      bodyA.fx = bodyA.fx + fx
      bodyA.fy = bodyA.fy + fy
      bodyA.fa = bodyA.fa + v2crs(rAx, rAy, fx, fy)
      bodyB.fx = bodyB.fx - fx
      bodyB.fy = bodyB.fy - fy
      bodyB.fa = bodyB.fa + v2crs(rBx, rBy, -fx, -fy)
    end
  end

  -- apply forces including gravity
  -- this is where external forces are added
  function apply_forces(dt)
    local gx, gy = state.gx, state.gy
    for _,body in pairs(bodies) do
      body.vx = body.vx + body.dofx*(body.g*gx + body.fx*body.imass)*dt
      body.vy = body.vy + body.dofy*(body.g*gy + body.fy*body.imass)*dt
      body.va = body.va + body.dofa*(body.fa*body.imoi)*dt
    end
  end

  -- integrate positions
  function integrate(dt)
    for _,body in pairs(bodies) do
      body.x = body.x + body.vx*dt
      body.y = body.y + body.vy*dt
      body.a = body.a + body.va*dt
      body.fx, body.fy, body.fa = 0, 0, 0
      body.transform()
    end
  end

  -- perform a single timestep
  state.step = function(dt)
    local beta = state.beta/dt

    local prev_collisions = collisions
    constraints = {}

    apply_springs()
    apply_forces(dt)

    handle_bounds(beta)
    handle_joints(beta)
    handle_collisions(beta)

    -- solve constraints
    local tmp, del, J, Jt, b, f, active
    for i=1,state.isteps do
      active = 0
      for j,c in pairs(constraints) do
        if c.active then
          local bodyA, bodyB = c.bodyA, c.bodyB
          J, b = c.J, c.b
          vxA, vyA, vaA, vxB, vyB, vaB, imassA, imoiA, imassB, imoiB =
            bodyA.vx, bodyA.vy, bodyA.va, bodyB.vx, bodyB.vy, bodyB.va,
            bodyA.imass, bodyA.imoi, bodyB.imass, bodyB.imoi

          if c.Jt then -- a tangential constraint (i.e. friction)
            Jt, f = c.Jt, c.f
            del = -(Jt[1]*vxA+Jt[2]*vyA+Jt[3]*vaA+Jt[4]*vxB+Jt[5]*vyB+Jt[6]*vaB)/c.JtM

            tmp = c.lambdat
            c.lambdat = mid(-f*c.lambda, c.lambdat+del, f*c.lambda)
            del = c.lambdat-tmp

            bodyA.vx = bodyA.vx + del*imassA*Jt[1]
            bodyA.vy = bodyA.vy + del*imassA*Jt[2]
            bodyA.va = bodyA.va + del*imoiA*Jt[3]
            bodyB.vx = bodyB.vx + del*imassB*Jt[4]
            bodyB.vy = bodyB.vy + del*imassB*Jt[5]
            bodyB.va = bodyB.va + del*imoiB*Jt[6]
          end

          del = -(J[1]*vxA+J[2]*vyA+J[3]*vaA+J[4]*vxB+J[5]*vyB+J[6]*vaB+b)/c.JM

          if c.inequality then
            tmp = c.lambda
            c.lambda = max(c.lambda+del, 0)
            del = c.lambda-tmp
          end

          bodyA.vx = bodyA.vx + del*imassA*J[1]
          bodyA.vy = bodyA.vy + del*imassA*J[2]
          bodyA.va = bodyA.va + del*imoiA*J[3]
          bodyB.vx = bodyB.vx + del*imassB*J[4]
          bodyB.vy = bodyB.vy + del*imassB*J[5]
          bodyB.va = bodyB.va + del*imoiB*J[6]

          -- deactivate a constraint if the change in the impulse becomes small
          if abs(del)<TINY then c.active = false
          else active = active + 1 end
        end
      end
      if active==0 then break end -- stop if we've solved all constraints
    end

    integrate(dt)
    tree.update() -- update aabb tree for next iteration
  end

  state.update = function()
    local fsteps = state.fsteps
    -- local dt = 1.0/(fsteps*stat(7))
    local dt = 1.0/(fsteps*15) -- FPS
    for i=1,fsteps do -- sub-frame steps
      state.step(dt)
      state.t = state.t + dt
    end
  end

  ppx = state
  return state
end

---------------------

-- returns true if the coordinates form a convex shape
function is_convex(coords)
  local numc, sign = #coords, 0
  for i,c1 in pairs(coords) do
    local c2, c3 =
      coords[i%numc+1], coords[(i+1)%numc+1]
    local ux, uy, vx, vy = c2[1]-c1[1], c2[2]-c1[2], c3[1]-c2[1], c3[2]-c2[2]
    local crs = ux*vy-uy*vx
    crs = crs/abs(crs)
    if sign==0 then sign = crs
    elseif sign~=crs then return false end
  end
  return true
end

-- generate a convex shape with given radius, r, and number of points, np.
-- sx and sy scale the shape in the given directions
function px_convex(r, np, sx, sy)
  rx = r*(sx or 1)
  ry = r*(sy or 1)
  local points, angle, da = {}, (np==4) and 0.25*PI or -0.5*PI, TWOPI/np
  for i=1,np do
    points[i] = { rx*cosine(angle), ry*sine(angle) }
    angle = angle + da
  end
  return points
end

-- utility functions to create triangles/rectangles
function px_triangle(w, h) return px_convex(ROOT2, 3, w/2, h/2) end
function px_rectangle(w, h) return px_convex(ROOT2, 4, w/2, h/2) end

---------------------

-- draws body geometry on the screen, converts between physical and screen coordinates
function draw_body(body, color)
  local state = ppx
  local ox, oy, scale = state.ox, state.oy, state.scale
  --circ(body.x/scale+ox, body.y/scale+oy, 2, color)
  for _,n in pairs(body.normals) do
    local p1, p2 = n.p1, n.p2
    line(p1.tx/scale+ox, p1.ty/scale+oy, p2.tx/scale+ox, p2.ty/scale+oy, color)
  end
end

-- draws aabb tree on the screen
function draw_tree(root)
  local state = ppx
  local ox, oy, scale = state.ox, state.oy, state.scale
  local box=root.box
  if root.type==BRANCH_NODE then
    rect(box.x1/scale+ox, box.y1/scale+oy, box.x2/scale+ox, box.y2/scale+oy, 0x9)
    draw_tree(root.right)
    draw_tree(root.left)
  else
    rect(box.x1/scale+ox, box.y1/scale+oy, box.x2/scale+ox, box.y2/scale+oy, 0x8)
  end
end
