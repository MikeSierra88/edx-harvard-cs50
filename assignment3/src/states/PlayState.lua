--[[
    GD50
    Match-3 Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until they exceed the number of points needed to get to the next level
    or until the time runs out, at which point they are brought back to the
    main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 255/255

    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    -- timer-based shiny transparency
    self.shinyAlpha = 0

    -- mouse functionality
    self.mouseX = 0
    self.mouseY = 0
    self.mouseOverBoard = false

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- set timer to rotate between shiny transparency every 03 seconds
    Timer.every(3, function() 
        -- transition to fully opaque in 0.25s then back
        Timer.tween(0.25, {[self] = {shinyAlpha = 1}})
            :finish(function()
                Timer.tween(0.25, {[self] = {shinyAlpha = 0}})
            end)
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)
end

function PlayState:enter(params)
    
    -- grab level # from the params we're passed
    self.level = params.level

    -- spawn a board and place it toward the right
    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16, self.level)

    -- grab score from params if it was passed
    self.score = params.score or 0

    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 1.25 * 1000

    -- check for valid moves
    self:checkPossibleMatches()
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- go back to start if time runs out
    if self.timer <= 0 then
        
        -- clear timers from prior PlayStates
        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then
        
        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
        -- will also clear!
        Timer.clear()

        gSounds['next-level']:play()

        -- change to begin game state with new level (incremented)
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    -- mouse functionality, position check

    self.mouseX, self.mouseY = push:toGame(love.mouse.getPosition())

    if self.mouseX > self.board.x and self.mouseX < (self.board.x + 256) and self.mouseY > self.board.y and self.mouseY < (self.board.y + 256) then
        self.mouseOverBoard = true
    else
        self.mouseOverBoard = false
    end

    if self.canInput then
        -- move cursor around based on bounds of grid, playing sounds
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        -- highlight tiles with mouse
        elseif self.mouseOverBoard then
            self.boardHighlightX = math.floor((self.mouseX - self.board.x) / 32)
            self.boardHighlightY = math.floor((self.mouseY - self.board.y) / 32)
        end

        -- if we've pressed enter, to select or deselect a tile or mouse was clicked while over the board...
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') or (love.mouse.wasClicked() and self.mouseOverBoard) then
            
            -- if same tile as currently highlighted, deselect
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            
            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                -- swap grid positions of tiles and check for match
                -- reverse swap if no match found
                self:swapTiles(self.highlightedTile, self.board.tiles[y][x], true)
                
            end
        end
    end

    Timer.update(dt)
end

--[[
    Calculates whether any matches were found on the board and tweens the needed
    tiles to their new destinations if so. Also removes tiles from the board that
    have matched and replaces them with new randomized tiles, deferring most of this
    to the Board class.
]]
function PlayState:calculateMatches(params)
    self.highlightedTile = nil
    -- if we have any matches, remove them and tween the falling blocks that result
    local matches = self.board:calculateMatches()
    
    if matches then
        if params and params.isSimulated then 
            return true 
        else

            gSounds['match']:stop()
            gSounds['match']:play()

            -- add score for each match
            for k, match in pairs(matches) do
                local matchValue = 1
                for k, tile in pairs(match) do
                    matchValue = matchValue * tile.variety
                end
                self.score = self.score + #match * 50 * (math.max(1, math.floor(matchValue / 4)))
                -- ASSIGNMENT
                -- add 3 seconds to timer for each match
                self.timer = self.timer + 3
                matchValue = 1
            end

            -- remove any tiles that matched from the board, making empty spaces
            
            
            self.board:removeMatches()

                    -- gets a table with tween values for tiles that should now fall
            local tilesToFall = self.board:getFallingTiles()

            -- tween new tiles that spawn from the ceiling over 0.25s to fill in
            -- the new upper gaps that exist
            Timer.tween(0.25, tilesToFall):finish(function()
                
                -- recursively call function in case new matches have been created
                -- as a result of falling blocks once new blocks have finished falling
                self:calculateMatches()
            end)
            
            self:checkPossibleMatches()
            -- return true if match was found
            return true
        end
    -- if no matches, we can continue playing
    else
        self.canInput = true
        -- return false if no match was found
        return false
    end
end

function PlayState:makeSwap(oldTile, newTile)
    local tempX = oldTile.gridX
    local tempY = oldTile.gridY

    oldTile.gridX = newTile.gridX
    oldTile.gridY = newTile.gridY
    newTile.gridX = tempX
    newTile.gridY = tempY

    -- swap tiles in the tiles table
    self.board.tiles[oldTile.gridY][oldTile.gridX] =
        oldTile

    self.board.tiles[newTile.gridY][newTile.gridX] = newTile
end

function PlayState:swapTiles(oldTile, newTile, firstAttempt)

    self:makeSwap(oldTile, newTile)

    -- tween coordinates between the two so they swap
    Timer.tween(0.1, {
        [oldTile] = {x = newTile.x, y = newTile.y},
        [newTile] = {x = oldTile.x, y = oldTile.y}
    })

    -- once the swap is finished, we can tween falling blocks as needed
    :finish(function()
        if firstAttempt and not self:calculateMatches() then
            Timer.after(0.25, function()
            self:swapTiles(newTile, oldTile, false) 
            end)
        end
    end)
end

-- Simulate a swap to check whether it would result in a match
function PlayState:simulateSwap(oldTile, newTile, firstAttempt)
    
    self:makeSwap(oldTile, newTile)
    
    if firstAttempt then 
        if self:calculateMatches({isSimulated = true}) then
            swapSuccessful = true
            self.matches = {}
        end
        self:simulateSwap(newTile, oldTile, false)
        if swapSuccessful then 
            swapSuccessful = false
            return true 
        end
    end
    return swapSuccessful
end

function PlayState:checkPossibleMatches()
    matchFound = false
    for i=1,8 do
        for j=1,8 do
            if i < 8 then
                matchFound = self:simulateSwap(self.board.tiles[j][i], self.board.tiles[j][i+1], true)
                if matchFound then
                    return true
                end
            end
            if j < 8 then
                matchFound = self:simulateSwap(self.board.tiles[j][i], self.board.tiles[j+1][i], true)
                if matchFound then
                    return true
                end
            end
        end
    end
    -- if no valid moves, create new board
    self:getNewBoard()
end

function PlayState:getNewBoard()
    -- remove all tiles
    for x=1,8 do
        for y=1,8 do
            self.board.tiles[y][x] = nil
        end
    end
    self.board.containsShiny = false
    -- gets a table with tween values for tiles that should now fall
    local tilesToFall = self.board:getFallingTiles()

    -- tween new tiles that spawn from the ceiling over 0.25s to fill in
    -- the new upper gaps that exist
    Timer.tween(0.25, tilesToFall):finish(function()
        
        -- recursively call function in case new matches have been created
        -- as a result of falling blocks once new blocks have finished falling
        self:calculateMatches()
    end)
end

function PlayState:render()
    -- render board of tiles
    self.board:render(self.shinyAlpha)

    -- render highlighted tile if it exists
    if self.highlightedTile then
        
        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(255/255, 255/255, 255/255, 96/255)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217/255, 87/255, 99/255, 255/255)
    else
        love.graphics.setColor(172/255, 50/255, 50/255, 255/255)
    end

    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99/255, 155/255/255, 255/255, 255/255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')
end