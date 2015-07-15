
local SpriteItem = import(".SpriteItem")

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    self.m_sprites = {}
    self.m_activeSprites = {}
    
    -- 8行8列
    self.m_row = 8
    self.m_col = 8
    self.m_spriteNumber = 8
    
    -- 添加背景精灵
    display.newSprite("background.png", display.cx, display.cy):addTo(self)
    display.addSpriteFrames("fruit.plist", "fruit.pvr.ccz")

    -- 添加精灵层
    self.m_playLayer = display.newLayer()
    self.m_playLayer:setContentSize(display.width, display.height)
    self.m_playLayer:ignoreAnchorPointForPosition(false)
    self.m_playLayer:align(display.CENTER)

    -- 将精灵层设置为中间位置
    self.m_playLayer:pos(display.cx,display.cy)
    self:add(self.m_playLayer)

    -- 初始化地图
    self:initSprites()

    -- 增加触摸事件
    self:initEvents()
end

function MainScene:initEvents()
    self:setTouchEnabled(true)
    self.m_playLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(self, self.touchCell))
end

--[[--
初始化精灵数组
]]
math.newrandomseed()
function MainScene:initSprites()
    -- 生成一半的精灵
    for i = 1, self.m_row * self.m_col / 2 do
        
        local type = math.random(1, self.m_spriteNumber)
        local sprite = SpriteItem.new(type)
        table.insert(self.m_sprites, sprite)
    end

    -- 拷贝到另外一半
    for i = 1, #self.m_sprites do
        local type = self.m_sprites[i]:getType()
        local sprite = SpriteItem.new(type)
        table.insert(self.m_sprites, sprite)
    end
    
    -- 随机打乱顺序，打乱13次
    for seq = 1, 13*2 do
        math.newrandomseed()
        for i = 1, #self.m_sprites do
            -- 随机要交换的行号和列号
            local row_org = math.random(1, self.m_row)
            local col_org = math.random(1, self.m_col)

            local row_dest = math.random(1, self.m_row)
            local col_dest = math.random(1, self.m_col)

            local sprite_org = self.m_sprites[(row_org-1)*self.m_col + col_org]
            local sprite_dest = self.m_sprites[(row_dest-1)*self.m_col + col_dest]

            -- 交换操作
            self.m_sprites[(row_org-1)*self.m_col + col_org], self.m_sprites[(row_dest-1)*self.m_col + col_dest]
            = self.m_sprites[(row_dest-1)*self.m_col + col_dest], self.m_sprites[(row_org-1)*self.m_col + col_org]
        end
    end
    
    -- 显示精灵
    local size = SpriteItem:getContentSize()
    for row = 1, self.m_row do
        for col = 1, self.m_col do
            local sprite  = self.m_sprites[(row-1)*self.m_col + col]:pos(col * size.width, row * size.height)
            sprite:setRowAndCol(row, col)
            self.m_playLayer:addChild(sprite)
        end
    end
    
    local size = SpriteItem:getContentSize()
    local playLayerWidth = (self.m_col+1)*size.width
    local playLayerHeight = (self.m_row+1)*size.height
    self.m_playLayer:setContentSize(playLayerWidth, playLayerHeight)
    if playLayerWidth > display.width then
        self.m_playLayer:setScale(display.width/playLayerWidth)
    end
    self.m_playLayer:pos(display.cx, display.cy)
end

--[[--
触摸响应函数
@param event 触摸数据
]]
function MainScene:touchCell(event)
    local pos = cc.p(event.x, event.y)
    
    local sprite = self:itemOfPoint(pos)
    if sprite and not sprite:getActive() then
        
        if #self.m_activeSprites == 0 then
            -- 没有选中任何的精灵
            sprite:active()
            table.insert(self.m_activeSprites, sprite)
            
        elseif #self.m_activeSprites == 1 then
            -- 前面选中了一个精灵
            local lastSprite = self.m_activeSprites[1]
            if lastSprite and not tolua.isnull(lastSprite) and lastSprite:getType() == sprite:getType() then
                -- 两个相同的精灵，是否能消除
                if self:checkLinkup(lastSprite, sprite) then
                    local row, col = lastSprite:getRowAndCol()
                    self.m_sprites[(row-1)*self.m_col + col] = nil
                    
                    row, col = sprite:getRowAndCol()
                    self.m_sprites[(row-1)*self.m_col + col] = nil
                    
                    table.remove(self.m_activeSprites)
                    lastSprite:removeSelf()
                    sprite:removeSelf()
                else
                    -- 不能连通，取消选择
                    lastSprite:inactive()
                    table.remove(self.m_activeSprites)
                end
                
            elseif lastSprite then
                -- 不同的精灵，取消选择
                lastSprite:inactive()
                table.remove(self.m_activeSprites)
            end
        end
    end
end

--[[--
检测两个精灵是否能连通
@param first 第一个精灵
 second 第二个精灵
]]
function MainScene:checkLinkup(first, second)
    local posa = {}
    local posb = {}
    posa.row, posa.col = first:getRowAndCol()
    posb.row, posb.col = second:getRowAndCol()
    
    -- 能直接连通
    local canLink = self:isDirectLink(posa, posb)
    if canLink then
        return canLink
    end

    -- 不能直接连通

    -- 经过一次拐角就能连通
    canLink = self:isOneCornerLink(posa, posb)
    if canLink then
        return canLink
    end
    
    -- 需要经过两次拐角才能连通
    canLink = self:isTwoCornerLink(posa, posb)
    if canLink then
        return canLink
    end
    
    return false
end


--[[--
检测两个精灵是否能直接连通
@param first 第一个精灵
        second 第二个精灵

@return true 可以直接连通
        false 不能直接连通
]]
function MainScene:isDirectLink(posa, posb)
    local firstRow, firstCol = posa.row, posa.col
    local secondRow, secondCol = posb.row, posb.col
    
    -- 相同位置的精灵
    if firstRow == secondRow and firstCol == secondCol then
        return false
    end
    
    if firstRow == secondRow then
        -- 相同行的精灵
        
        -- 首尾行的两个精灵只要在同一行就可以连通
        if firstRow == 1 or firstRow == self.m_row then
            return true
        end
        
        -- 确定相隔的距离
        local steps = secondCol - firstCol
        for i = steps/math.abs(steps), steps, steps/math.abs(steps) do
            local sp = self.m_sprites[(firstRow-1)*self.m_col + firstCol + i]
            local row, col = firstRow, firstCol+i
            if col == secondCol then
                return true
            elseif sp ~= nil then
                return false
            end
        end
        
    elseif firstCol == secondCol then
        -- 相同列的精灵
        
        -- 首尾列的两个精灵只要在同一列就可以连通
        if firstCol == 1 or firstCol == self.m_col then
            return true
        end
        
        -- 确定相隔的距离
        local steps = secondRow - firstRow
        for i = steps/math.abs(steps), steps, steps/math.abs(steps) do
            local sp = self.m_sprites[(firstRow-1+i)*self.m_col + firstCol]
            local row, col = firstRow+i, firstCol
            if row == secondRow then
                return true
            elseif sp ~= nil then
                return false
            end
        end
    else
        return false
    end

    return true
end

--[[--
是否能经过一次拐角就能到
@param first 第一个精灵
second 第二个精灵

@return true 可以直接连通
false 不能直接连通
]]
function MainScene:isOneCornerLink(posa, posb)
    local row, col = posa.row, posa.col

    -- 往四个方向检查看是否有能和第二个精灵直接连通的精灵
    
    -- 相同位置的精灵
    if row == posb.row and col == posb.col then
        return false
    end
    
    -- 左
    local steps = col - 1
    for i = 1, steps do
        local sp = self.m_sprites[(row-1) * self.m_col + col - i]
        if sp ~= nil then
            break
        elseif self:isDirectLink({row=row, col=col-i}, posb) then
            return true
        end
    end

    -- 右
    steps = self.m_col - col
    for i = 1, steps do
        local sp = self.m_sprites[(row-1) * self.m_col + col + i]
        if sp ~= nil then
            break
        elseif self:isDirectLink({row=row, col=col+i}, posb) then
            return true
        end
    end

    -- 上
    steps = self.m_row - row
    for i = 1, steps do
        local sp = self.m_sprites[(row-1+i) * self.m_col + col]
        if sp ~= nil then
            break
        elseif self:isDirectLink({row=row+i, col=col}, posb) then
            return true
        end
    end

    -- 下
    steps = row - 1
    for i = 1, steps do
        local sp = self.m_sprites[(row-1-i) * self.m_col + col]
        if sp ~= nil then
            break
        elseif self:isDirectLink({row=row-i, col=col}, posb) then
            return true
        end
    end

    return false
end

--[[--
是否能经过两次拐角就能到
@param first 第一个精灵
second 第二个精灵

@return true 可以直接连通
false 不能直接连通
]]
function MainScene:isTwoCornerLink(posa, posb)
    local row, col = posa.row, posa.col

    -- 往四个方向检查看是否有能和第二个精灵直接连通的精灵
    -- 相同位置的精灵
    if row == posb.row and col == posb.col then
        return false
    end
    
    -- 左
    local steps = col - 1
    for i = 1, steps do
        local sp = self.m_sprites[(row-1) * self.m_col + col - i]
        if sp ~= nil then
            break
        elseif self:isOneCornerLink({row=row, col=col-i}, posb) then
            return true
        end
    end

    -- 右
    steps = self.m_col - col
    for i = 1, steps do
        local sp = self.m_sprites[(row-1) * self.m_col + col + i]
        if sp ~= nil then
            break
        elseif self:isOneCornerLink({row=row, col=col+i}, posb) then
            return true
        end
    end

    -- 上
    steps = self.m_row - row
    for i = 1, steps do
        local sp = self.m_sprites[(row-1+i) * self.m_col + col]
        if sp ~= nil then
            break
        elseif self:isOneCornerLink({row=row+i, col=col}, posb) then
            return true
        end
    end

    -- 下
    steps = row - 1
    for i = 1, steps do
        local sp = self.m_sprites[(row-1-i) * self.m_col + col]
        if sp ~= nil then
            break
        elseif self:isOneCornerLink({row=row-i, col=col}, posb) then
            return true
        end
    end

    return false
end

--[[--
选中的是哪个精灵
@param point 触摸点
]]
function MainScene:itemOfPoint(point)
    local item = nil
    local rect = nil

    point = self.m_playLayer:convertToNodeSpace(point)
    for row = 1, self.m_row do
        for col = 1, self.m_col do
            item = self.m_sprites[(row-1) * self.m_col + col]
            if (item) then
                rect = cc.rect(item:getPositionX() - (item:getContentSize().width / 2),
                                item:getPositionY() - (item:getContentSize().height / 2),
                                item:getContentSize().width,
                                item:getContentSize().height)
                                
                if (cc.rectContainsPoint(rect, point)) then
                    return item
                end
            end
        end
    end
end

function MainScene:onEnter()
    
end

function MainScene:onExit()
end

return MainScene
