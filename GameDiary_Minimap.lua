
-- GameDiary_Minimap.lua
-- 小地图按钮：可拖拽旋转，点击打开日记本


GD_MinimapButton = nil;
GD_MinimapIsDragging = false;

------------------------------------------------------------
-- 初始化小地图按钮
------------------------------------------------------------
function GD_InitMinimapButton()
    -- 如果用户设置不显示，则不创建
    if GameDiaryDB and GameDiaryDB.settings and not GameDiaryDB.settings.minimapShow then
        return;
    end

    -- 创建按钮
    local btn = CreateFrame("Button", "GD_MinimapButton", Minimap);
    GD_MinimapButton = btn;

    btn:SetFrameStrata("MEDIUM");
    btn:SetWidth(33);
    btn:SetHeight(33);
    btn:SetToplevel(true);
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    btn:RegisterForDrag("LeftButton");

    -- 设置图标（使用魔兽原生书本图标）
    local icon = btn:CreateTexture("GD_MinimapButtonIcon", "BACKGROUND");
    icon:SetWidth(20);
    icon:SetHeight(20);
    icon:SetPoint("CENTER", 0, 1);
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09");
    icon:SetAlpha(0.9);

    -- 设置高亮边框
    local highlight = btn:CreateTexture("GD_MinimapButtonHighlight", "HIGHLIGHT");
    highlight:SetWidth(33);
    highlight:SetHeight(33);
    highlight:SetPoint("CENTER", 0, 0);
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight");
    highlight:SetAlpha(0.5);

    -- 定位到小地图边缘
    GD_UpdateMinimapPosition();

    -- 脚本
    btn:SetScript("OnClick", GD_MinimapButton_OnClick);
    btn:SetScript("OnDragStart", GD_MinimapButton_OnDragStart);
    btn:SetScript("OnDragStop", GD_MinimapButton_OnDragStop);
    btn:SetScript("OnEnter", GD_MinimapButton_OnEnter);
    btn:SetScript("OnLeave", GD_MinimapButton_OnLeave);
    btn:SetScript("OnUpdate", GD_MinimapButton_OnUpdate);
end

------------------------------------------------------------
-- 更新小地图按钮位置
------------------------------------------------------------
function GD_UpdateMinimapPosition()
    if not GD_MinimapButton then return; end

    local settings = GameDiaryDB and GameDiaryDB.settings or {};
    local angle = settings.minimapAngle or GD_CONFIG.MINIMAP_DEFAULT_ANGLE;
    local radius = settings.minimapRadius or GD_CONFIG.MINIMAP_DEFAULT_RADIUS;

    -- 将角度转换为弧度
    local rad = angle * math.pi / 180;

    -- 计算位置（小地图中心为原点）
    local x = math.cos(rad) * radius;
    local y = math.sin(rad) * radius;

    GD_MinimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y);
end

------------------------------------------------------------
-- 点击事件
------------------------------------------------------------
function GD_MinimapButton_OnClick()
    local frame = GD_Utils:GetFrame("GameDiaryFrame");
    if frame then
        if frame:IsShown() then
            frame:Hide();
            PlaySound(GD_CONFIG.SOUND_CLOSE);
        else
            frame:Show();
            PlaySound(GD_CONFIG.SOUND_OPEN);
        end
    end
end

------------------------------------------------------------
-- 拖拽事件
------------------------------------------------------------
function GD_MinimapButton_OnDragStart()
    GD_MinimapIsDragging = true;
end

function GD_MinimapButton_OnDragStop()
    GD_MinimapIsDragging = false;
end

------------------------------------------------------------
-- 拖拽更新（OnUpdate中处理）
------------------------------------------------------------
function GD_MinimapButton_OnUpdate()
    if not GD_MinimapIsDragging then return; end

    local mx, my = GetCursorPosition();
    local minimapCenterX, minimapCenterY = Minimap:GetCenter();
    local scale = Minimap:GetEffectiveScale();

    mx = mx / scale;
    my = my / scale;

    -- 计算相对于小地图中心的偏移
    local dx = mx - minimapCenterX;
    local dy = my - minimapCenterY;

    -- 计算角度（从右侧开始，顺时针）
    local angle = math.deg(math.atan2(dy, dx));
    if angle < 0 then
        angle = angle + 360;
    end

    -- 计算半径
    local radius = math.sqrt(dx * dx + dy * dy);
    radius = math.max(10, math.min(radius, 90)); -- 限制范围

    -- 保存设置
    if GameDiaryDB and GameDiaryDB.settings then
        GameDiaryDB.settings.minimapAngle = angle;
        GameDiaryDB.settings.minimapRadius = radius;
    end

    -- 更新位置
    GD_UpdateMinimapPosition();
end

------------------------------------------------------------
-- Tooltip
------------------------------------------------------------
function GD_MinimapButton_OnEnter()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT");
    GameTooltip:SetText("游戏日记本", 1, 0.84, 0);
    GameTooltip:AddLine("点击打开/关闭日记本", 1, 1, 1);
    GameTooltip:AddLine("拖动可调整位置", 0.7, 0.7, 0.7);
    GameTooltip:AddLine("输入 /gd 打开", 0.7, 0.7, 0.7);
    GameTooltip:Show();
end

function GD_MinimapButton_OnLeave()
    GameTooltip:Hide();
end
