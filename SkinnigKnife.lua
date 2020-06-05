local combat = false
local equiped = false
local unitGuid = nil
local currentGuid = nil
local skinningGuid = nil
local skinnedGuid = nil
local skillLevel = 0
local skillLine = 0

local remainTime = 0
local weapon = nil
local gloves = nil
local skinningWeapon = nil
local skinningGloves = nil
local weaponSlot = 0
local glovesSlot = 0
local loaded = false
local version = "0.2"


function SkinningKnife_OnLoad(self)
    weaponSlot = GetInventorySlotInfo("MainHandSlot")
    glovesSlot = GetInventorySlotInfo("HandsSlot")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function SkinningKnife_Register(self)
    skillLine, skillLevel = SkinningKnife_GetSkinningInfo()
    if skillLevel<1 then
        print("Skinning Knife "..version..": no skinning skill")
        return
    end

    print("Skinning Knife "..version..": skinning " .. skillLevel)

    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    self:RegisterEvent("CURSOR_UPDATE")
    self:RegisterEvent("LOOT_CLOSED")
    self:RegisterEvent("UNIT_SPELLCAST_START")
    self:RegisterEvent("BANKFRAME_CLOSED")
end

function SkinningKnife_OnEvent(self, event, ...)
    if event=="PLAYER_ENTERING_WORLD" then
        SkinningKnife_Register(self)
    elseif event=="BANKFRAME_CLOSED" then
        SkinningKnife_CheckInventory()
    elseif loaded and not skinningGloves and not skinningWeapon then
        return
    elseif event=="PLAYER_REGEN_ENABLED" then
        combat=false
        if equiped then
            SkinningKnife_UnEquip("combat")
        end
    elseif not combat then
        if event=="PLAYER_REGEN_DISABLED" then
            combat=true
        elseif event=="UPDATE_MOUSEOVER_UNIT" then
            unitGuid = UnitGUID("mouseover")
            if unitGuid and SkinningKnife_Skinnabe() then
                SkinningKnife_CheckTarget()
            end
        elseif equiped then
            if event=="UNIT_SPELLCAST_START" then
                local target, castGUID, spellID = ...
                if target == "player" then
                    if spellID == 10768 then
                        skinningGuid = unitGuid
                        SkinningKnife_SetTimer(5)
                    end
                end
            elseif event=="LOOT_CLOSED" then
                skinnedGuid = skinningGuid
                SkinningKnife_UnEquip("loot closed")
                if skillLevel<300 then
                    local name, _, _, skillRank, _, skillModifier = GetSkillLineInfo(skillLine)
                    skillLevel = skillRank
                end

            end
        elseif unitGuid and event=="CURSOR_UPDATE"then
            SkinningKnife_CheckTarget()
        end
    end
end

function SkinningKnife_CheckTarget()
    if not SkinningKnife_Skinnabe() then 
        return
    end

    local level = UnitLevel("mouseover")
    local skill = 1
    if level > 20 then
        skill = level*5
    elseif level > 10 then 
        skill = (level - 10)*10
    end

    if skill<(skillLevel-50) or skinnedGuid == unitGuid then
        return
    end

    currentGuid = unitGuid
    if not equiped then
        SkinningKnife_Equip()
    end
    SkinningKnife_SetTimer(5)
end

function SkinningKnife_Skinnabe()
    if not UnitIsDead("mouseover") then
        return false
    end
    for i = 3, GameTooltip:NumLines() do
        if (_G["GameTooltipTextLeft"..i]:GetText()==UNIT_SKINNABLE_LEATHER) then
            return true
        end
    end
    return false
end

function SkinningKnife_Timer()
    if not equiped then
        remainTime = 0;
        return
    end
    if not unitGuid or unitGuid ~= currentGuid then
        remainTime = remainTime-1;
    end
    if remainTime>0 then
        C_Timer.After(1, SkinningKnife_Timer)
    else
        SkinningKnife_UnEquip("timer");
    end
end

function SkinningKnife_SetTimer(time)
    if not equiped then 
        remainTime = 0;
        return
    end
    if remainTime<=0 then
        C_Timer.After(1, SkinningKnife_Timer)
    end
    remainTime = time
end

function SkinningKnife_Equip()
    if not loaded then
        SkinningKnife_CheckInventory()
        loaded = true
    end
    equiped = true
    if skinningWeapon then
        local myweapon = GetInventoryItemID("player", weaponSlot)
        if myweapon ~= skinningWeapon then
            weapon = myweapon
            EquipItemByName(skinningWeapon)
        end
    end
    if skinningGloves then
        local mygloves = GetInventoryItemID("player", glovesSlot)
        if mygloves ~= skinningGloves then
            gloves = mygloves
            EquipItemByName(skinningGloves)
        end
    end
end

function SkinningKnife_UnEquip(reason)
    if skinningWeapon then
        local myweapon = GetInventoryItemID("player", weaponSlot)
        if myweapon ~= weapon then
            EquipItemByName(weapon)
        end
    end
    if combat then
        return
    end
    if skinningGloves then
        local mygloves = GetInventoryItemID("player", glovesSlot)
        if mygloves ~= gloves then
            EquipItemByName(gloves)
        end
    end
    equiped = false
end

function SkinningKnife_CheckInventory()
    skinningGloves = nil
    skinningWeapon = nil
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local item = GetContainerItemID(bag, slot)
            if item then
                local itemtname, _, _, _, _, _, _, _, itemequip = GetItemInfo(item);
                if item==12709 or item==19901 then
                    skinningWeapon = item
                elseif itemequip == "INVTYPE_HAND" then
                    local _, _, _, _, _, _, itemlink = GetContainerItemInfo(bag, slot)
                    local id, enchantId = itemlink:match("item:(%d+):(%d+):")
                    if enchantId=="865" then
                        skinningGloves = item
                    end
                end
            end
        end
    end
end

function SkinningKnife_GetSkinningInfo()
    local skinning = GetSpellInfo(8613)
    for skillIndex = 1, GetNumSkillLines() do
        local name, _, _, skillRank, _, skillModifier = GetSkillLineInfo(skillIndex)
        if name == skinning then   
            return skillIndex, skillRank
        end
    end
    return 0, 0
end