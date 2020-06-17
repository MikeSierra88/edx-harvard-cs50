--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Projectile = Class{}

function Projectile:init(object, direction, playerY)
    self.x = object.x
    self.playerY = playerY
    self.y = object.y
    self.width = object.width
    self.height = object.height
    self.type = object.type
    self.texture = object.texture
    self.frame = object.frame
    self.width = object.width
    self.height = object.height
    self.solid = true
    self.consumable = false
    self.defaultState = object.defaultState
    self.state = self.defaultState
    self.states = object.states
    self.direction = direction
    self.travelled = 0
end

function Projectile:update(dt)
    local distance  = PROJECTILE_SPEED * dt
    if self.direction == 'right' then
        self.x = self.x + distance
        if self.y < self.playerY then
            self.y = self.y + 1
        end
    elseif self.direction == 'down' then
        self.y = self.y + distance
    elseif self.direction == 'left' then
        self.x = self.x - distance
        if self.y < self.playerY then
            self.y = self.y + 1
        end
    else
        self.y = self.y - distance
    end
    self.travelled = self.travelled + distance
    if self.travelled > 64 or Projectile:wallHit(self) then
        gSounds['door']:play()
        self.expired = true
    end
end

function Projectile:render(adjacentOffsetX, adjacentOffsetY)
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.states[self.state].frame or self.frame],
        self.x + adjacentOffsetX, self.y + adjacentOffsetY)
end

function Projectile:wallHit(self)
    local bottomEdge = VIRTUAL_HEIGHT - (VIRTUAL_HEIGHT - MAP_HEIGHT * TILE_SIZE) 
    + MAP_RENDER_OFFSET_Y - TILE_SIZE
    return ( self.x <= MAP_RENDER_OFFSET_X + TILE_SIZE or self.x + self.width >= VIRTUAL_WIDTH - TILE_SIZE * 2 
        or self.y <= MAP_RENDER_OFFSET_Y + TILE_SIZE - self.height / 2 or self.y + self.height >= bottomEdge )
end