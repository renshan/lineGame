
--[[--
连连看精灵类
@param type: 精灵类型
]]

local SpriteItem = class("SpriteItem", function (type1)
	type1 = type1 or defaultImage
    local sprite = display.newSprite("#fruit" .. type1 .. "_1.png")
    sprite.m_type = type1
	return sprite
end)

function SpriteItem:ctor()
end

-- 精灵显示选中状态
function SpriteItem:active()
    self:changeActiveState(true)
end

-- 精灵显示正常状态
function SpriteItem:inactive()
    self:changeActiveState(false)
end

--[[--
改变精灵状态
@param bool state 精灵状态
]]
function SpriteItem:changeActiveState(activeState)
    local frame = nil
    if (activeState) then
        frame = display.newSpriteFrame("fruit"  .. self.m_type .. '_2.png')
    else
        frame = display.newSpriteFrame("fruit"  .. self.m_type .. '_1.png')
    end

    self:setSpriteFrame(frame)
    self.m_activeState = activeState
end

--[[--
    设置精灵的行和列信息
]]
function SpriteItem:setRowAndCol(row, col)
    self.m_row, self.m_col = row, col
end

function SpriteItem:getRowAndCol()
    return self.m_row, self.m_col
end

--[[--
    获取精灵类型
]]
function SpriteItem:getType()
    return self.m_type
end

function SpriteItem:getActive()
    return self.m_activeState
end

--[[--
    获取精灵大小
]]
function SpriteItem:getContentSize()
    if self.m_contentSize == nil then
        self.m_contentSize = self:getSpriteSize()
    end
    
    return self.m_contentSize
end

function SpriteItem:getSpriteSize()
    local sprite = display.newSprite("#fruit1_1.png")
    return sprite:getContentSize()
end

return SpriteItem
