--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerWalkState = Class{__includes = EntityWalkState}

function PlayerWalkState:init(player, dungeon)
    self.entity = player
    self.dungeon = dungeon

    -- render offset for spaced character sprite
    self.entity.offsetY = 5
    self.entity.offsetX = 0
end

function PlayerWalkState:update(dt)
    if love.keyboard.isDown('left') then
        self.entity.direction = 'left'
        if  self.entity.carriedPot then
            self.entity:changeAnimation('carry-left')
        else
            self.entity:changeAnimation('walk-left')
        end
    elseif love.keyboard.isDown('right') then
        self.entity.direction = 'right'
        if  self.entity.carriedPot then
            self.entity:changeAnimation('carry-right')
        else
            self.entity:changeAnimation('walk-right')
        end
    elseif love.keyboard.isDown('up') then
        self.entity.direction = 'up'
        if  self.entity.carriedPot then
            self.entity:changeAnimation('carry-up')
        else
            self.entity:changeAnimation('walk-up')
        end
    elseif love.keyboard.isDown('down') then
        self.entity.direction = 'down'
        if  self.entity.carriedPot then
            self.entity:changeAnimation('carry-down')
        else
            self.entity:changeAnimation('walk-down')
        end
    else
        self.entity:changeState('idle')
    end

    if love.keyboard.wasPressed('space') and not self.entity.carriedPot then
        self.entity:changeState('swing-sword')
    end

    -- if enter is pressed, check whether carrying pot or available for pickup
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then 
        -- if already carrying pot, throw it
        if self.entity.carriedPot then
            self.entity.carriedPot.thrown = true
            self.entity.carriedPot = Nil
        -- if not carrying but one in range for pickup, pick it up
        elseif self.entity.pickablePot then
            self.entity.carriedPot = self.entity.pickablePot
            self.entity:changeState('pickup')
        end
    end

    -- perform base collision detection against walls
    EntityWalkState.update(self, dt)

    -- if we bumped something when checking collision, check any object collisions
    if self.bumped then
        if self.entity.direction == 'left' then
            -- temporarily adjust position
            self.entity.x = self.entity.x - PLAYER_WALK_SPEED * dt
            
            for k, doorway in pairs(self.dungeon.currentRoom.doorways) do
                if self.entity:collides(doorway) and doorway.open then

                    -- shift entity to center of door to avoid phasing through wall
                    self.entity.y = doorway.y + 4
                    Event.dispatch('shift-left')
                end
            end

            -- readjust
            self.entity.x = self.entity.x + PLAYER_WALK_SPEED * dt
            
        elseif self.entity.direction == 'right' then
            
            -- temporarily adjust position
            
            self.entity.x = self.entity.x + PLAYER_WALK_SPEED * dt
            
            for k, doorway in pairs(self.dungeon.currentRoom.doorways) do
                if self.entity:collides(doorway) and doorway.open then

                    -- shift entity to center of door to avoid phasing through wall
                    self.entity.y = doorway.y + 4
                    Event.dispatch('shift-right')
                end
            end

            -- readjust
            self.entity.x = self.entity.x - PLAYER_WALK_SPEED * dt

        elseif self.entity.direction == 'up' then
            
            -- temporarily adjust position
            self.entity.y = self.entity.y - PLAYER_WALK_SPEED * dt
            
            for k, doorway in pairs(self.dungeon.currentRoom.doorways) do
                if self.entity:collides(doorway) and doorway.open then

                    -- shift entity to center of door to avoid phasing through wall
                    self.entity.x = doorway.x + 8
                    Event.dispatch('shift-up')
                end
            end

            -- readjust
            self.entity.y = self.entity.y + PLAYER_WALK_SPEED * dt
        else
            
            -- temporarily adjust position
            self.entity.y = self.entity.y + PLAYER_WALK_SPEED * dt
            
            for k, doorway in pairs(self.dungeon.currentRoom.doorways) do
                if self.entity:collides(doorway) and doorway.open then

                    -- shift entity to center of door to avoid phasing through wall
                    self.entity.x = doorway.x + 8
                    Event.dispatch('shift-down')
                end
            end

            -- readjust
            self.entity.y = self.entity.y - PLAYER_WALK_SPEED * dt
        end
    end

    -- avoid walking through pots
    if self.entity.pot then
        if self.entity.direction == 'left' and self.entity.x > self.entity.pot.x and not self:verticalPotCheck() then
            self.entity.x = self.entity.x + PLAYER_WALK_SPEED * dt
        elseif self.entity.direction == 'right' and self.entity.x < self.entity.pot.x and not self:verticalPotCheck() then
            self.entity.x = self.entity.x - PLAYER_WALK_SPEED * dt
        elseif self.entity.direction == 'down' and self.entity.y < self.entity.pot.y and not self:horizontalPotCheck() then
            self.entity.y = self.entity.y - PLAYER_WALK_SPEED * dt
        elseif self.entity.direction == 'up' and self.entity.y > self.entity.pot.y and not self:horizontalPotCheck() then
            self.entity.y = self.entity.y + PLAYER_WALK_SPEED * dt
        end
    end
    self.entity.pot = Nil
end

-- checks vertical overlay between player and touched pot
function PlayerWalkState:verticalPotCheck()
    return (self.entity.y + self.entity.height < self.entity.pot.y) and (self.entity.y > self.entity.pot.y + self.entity.pot.height)
end

-- checks horizontal overlay between player and touched pot
function PlayerWalkState:horizontalPotCheck()
    return (self.entity.x + self.entity.width < self.entity.pot.x) and (self.entity.x > self.entity.pot.x + self.entity.pot.width)
end