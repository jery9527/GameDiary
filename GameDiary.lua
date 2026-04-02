
-- GameDiary.lua
-- 核心逻辑：数据管理、CRUD、搜索筛选排序、导入导出、事件处理


------------------------------------------------------------
-- 全局状态
------------------------------------------------------------
GD_State = {
    currentBook = nil,        -- 当前选中的日记本名称
    currentPage = 1,          -- 当前页码
    selectedRecordId = nil,   -- 当前选中的记录ID
    filterType = "all",       -- 筛选类型: "all", "pitfall", "fun"
    searchText = "",          -- 搜索关键词
    sortOrder = "newest",     -- 排序方式: "newest", "oldest"
    filteredRecords = {},     -- 筛选后的记录列表
    isDirty = false,          -- 数据是否已修改
};

------------------------------------------------------------
-- 修复 1.12 版本 ScrollFrame 不显示滚动条的通用函数
------------------------------------------------------------
local function FixScrollFrameHeight(scrollFrame, editBox)
    if not scrollFrame or not editBox then return end
    -- 1. 获取文字实际高度
    local textHeight = editBox:GetTextHeight();
    --DEFAULT_CHAT_FRAME:AddMessage(textHeight);
    -- 2. 获取滚动框可见高度
    local scrollHeight = scrollFrame:GetHeight();
    -- 3. 如果文字少，高度就等于框高；如果文字多，就等于文字高度+留白
    local newHeight = math.max(textHeight + 20, scrollHeight);
    -- 4. 动态撑开输入框
    editBox:SetHeight(newHeight);
    -- 5. 强制通知滚动条重新计算！
    scrollFrame:UpdateScrollChildRect();
end

------------------------------------------------------------
-- 初始化数据库
------------------------------------------------------------
function GD_InitDB()
    if not GameDiaryDB then
        GameDiaryDB = {
            books = {},
            currentBook = nil,
            settings = {
                minimapAngle = GD_CONFIG.MINIMAP_DEFAULT_ANGLE,
                minimapRadius = GD_CONFIG.MINIMAP_DEFAULT_RADIUS,
                minimapShow = true,
            },
            dataVersion = GD_CONFIG.DATA_VERSION,
        };
    end

    -- 数据版本迁移
    if GameDiaryDB.dataVersion < GD_CONFIG.DATA_VERSION then
        GD_MigrateDB();
    end

    -- 确保settings存在
    if not GameDiaryDB.settings then
        GameDiaryDB.settings = {
            minimapAngle = GD_CONFIG.MINIMAP_DEFAULT_ANGLE,
            minimapRadius = GD_CONFIG.MINIMAP_DEFAULT_RADIUS,
            minimapShow = true,
        };
    end

    -- 恢复上次选中的日记本
    if GameDiaryDB.currentBook and GameDiaryDB.books[GameDiaryDB.currentBook] then
        GD_State.currentBook = GameDiaryDB.currentBook;
    end
end

------------------------------------------------------------
-- 数据库迁移（预留）
------------------------------------------------------------
function GD_MigrateDB()
    -- 未来版本升级时在此处理数据迁移
    GameDiaryDB.dataVersion = GD_CONFIG.DATA_VERSION;
end

------------------------------------------------============
-- 日记本操作
------------------------------------------------------------

-- 创建日记本
function GD_CreateBook(name)
    if not name or name == "" then return false; end
    name = string.gsub(name, "^%s*(.-)%s*$", "%1"); -- 去首尾空格

    if GameDiaryDB.books[name] then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 日记本「" .. name .. "」已存在！|r");
        return false;
    end

    GameDiaryDB.books[name] = {
        records = {},
        createTime = GD_Utils:GetTimestamp(),
    };

    GD_SelectBook(name);
    DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_FUN .. "[游戏日记本] 日记本「" .. name .. "」创建成功！|r");
    return true;
end

-- 删除日记本
function GD_DeleteBook(name)
    if not name or not GameDiaryDB.books[name] then return false; end

    GameDiaryDB.books[name] = nil;

    if GD_State.currentBook == name then
        GD_State.currentBook = nil;
        GD_State.selectedRecordId = nil;
        GD_State.currentPage = 1;
        GameDiaryDB.currentBook = nil;

        -- 自动切换到第一个可用的日记本
        for bName, _ in pairs(GameDiaryDB.books) do
            GD_SelectBook(bName);
            break;
        end
    end

    DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_YELLOW .. "[游戏日记本] 日记本「" .. name .. "」已删除。|r");
    GD_RefreshUI();
    return true;
end

-- 重命名日记本
function GD_RenameBook(oldName, newName)
    if not oldName or not newName then return false; end
    newName = string.gsub(newName, "^%s*(.-)%s*$", "%1");

    if not GameDiaryDB.books[oldName] then return false; end
    if oldName == newName then return false; end
    if GameDiaryDB.books[newName] then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 日记本「" .. newName .. "」已存在！|r");
        return false;
    end

    -- 复制数据到新名称
    GameDiaryDB.books[newName] = GD_Utils:DeepCopy(GameDiaryDB.books[oldName]);
    GameDiaryDB.books[oldName] = nil;

    -- 更新当前选中
    if GD_State.currentBook == oldName then
        GD_State.currentBook = newName;
        GameDiaryDB.currentBook = newName;
    end

    DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_FUN .. "[游戏日记本] 日记本已重命名为「" .. newName .. "」。|r");
    GD_RefreshUI();
    return true;
end

-- 选择日记本
function GD_SelectBook(name)
    if not name or not GameDiaryDB.books[name] then return false; end

    GD_State.currentBook = name;
    GD_State.currentPage = 1;
    GD_State.selectedRecordId = nil;
    GD_State.filterType = "all";
    GD_State.searchText = "";
    GameDiaryDB.currentBook = name;

    GD_RefreshUI();
    return true;
end

-- 获取所有日记本名称
function GD_GetBookNames()
    local names = {};
    for name, _ in pairs(GameDiaryDB.books) do
        table.insert(names, name);
    end
    table.sort(names);
    return names;
end

------------------------------------------------------------
-- 记录操作（CRUD）
------------------------------------------------------------

-- 新增记录
function GD_AddRecord(recType, title, content)
    if not GD_State.currentBook then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 请先选择或创建一个日记本！|r");
        return false;
    end

    if not recType or not title or title == "" then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 请填写记录类型和标题！|r");
        return false;
    end

    local info = GD_Utils:GetPlayerInfo();
    local ts = GD_Utils:GetTimestamp();

    local record = {
        id = GD_Utils:GenerateId(),
        type = recType,
        title = title,
        content = content or "",
        charName = info.charName,
        charRace = info.charRace,
        charClass = info.charClass,
        charLevel = info.charLevel,
        zone = info.zone,
        subZone = info.subZone,
        posX = info.posX,
        posY = info.posY,
        createTime = ts,
        modifyTime = ts,
        gameTime = GD_Utils:GetGameTime(),
    };

    local book = GameDiaryDB.books[GD_State.currentBook];
    table.insert(book.records, record);

    GD_State.selectedRecordId = record.id;
    GD_State.isDirty = true;

    PlaySound(GD_CONFIG.SOUND_SAVE);
    DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_FUN .. "[游戏日记本] 记录已保存！|r");

    GD_RefreshFilteredRecords();
    GD_RefreshUI();
    return true;
end

-- 更新记录
function GD_UpdateRecord(id, recType, title, content)
    if not GD_State.currentBook then return false; end
    if not id then return false; end

    local book = GameDiaryDB.books[GD_State.currentBook];
    local idx = GD_Utils:ArrayFind(book.records, id, "id");
    if not idx then return false; end

    local record = book.records[idx];
    record.type = recType or record.type;
    record.title = title or record.title;
    record.content = content or record.content;
    record.modifyTime = GD_Utils:GetTimestamp();

    GD_State.isDirty = true;

    PlaySound(GD_CONFIG.SOUND_SAVE);
    DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_FUN .. "[游戏日记本] 记录已更新！|r");

    GD_RefreshFilteredRecords();
    GD_RefreshUI();
    return true;
end

-- 删除记录
function GD_DeleteRecord(id)
    if not GD_State.currentBook then return false; end
    if not id then return false; end

    local book = GameDiaryDB.books[GD_State.currentBook];
    local idx = GD_Utils:ArrayFind(book.records, id, "id");
    if not idx then return false; end

    GD_Utils:ArrayRemove(book.records, idx);

    if GD_State.selectedRecordId == id then
        GD_State.selectedRecordId = nil;
    end

    GD_State.isDirty = true;

    PlaySound(GD_CONFIG.SOUND_DELETE);
    DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_YELLOW .. "[游戏日记本] 记录已删除。|r");

    -- 调整页码
    GD_RefreshFilteredRecords();
    local totalPages = math.ceil(GD_Utils:ArraySize(GD_State.filteredRecords) / GD_CONFIG.RECORDS_PER_PAGE);
    if totalPages == 0 then totalPages = 1; end
    if GD_State.currentPage > totalPages then
        GD_State.currentPage = totalPages;
    end

    GD_RefreshUI();
    return true;
end

-- 获取记录
function GD_GetRecord(id)
    if not GD_State.currentBook or not id then return nil; end
    local book = GameDiaryDB.books[GD_State.currentBook];
    local idx = GD_Utils:ArrayFind(book.records, id, "id");
    if not idx then return nil; end
    return book.records[idx];
end

-- 获取当前选中的记录
function GD_GetSelectedRecord()
    return GD_GetRecord(GD_State.selectedRecordId);
end

------------------------------------------------------------
-- 搜索、筛选、排序
------------------------------------------------------------

-- 刷新筛选后的记录列表
function GD_RefreshFilteredRecords()
    GD_State.filteredRecords = {};

    if not GD_State.currentBook then return; end
    local book = GameDiaryDB.books[GD_State.currentBook];
    if not book or not book.records then return; end

    local records = {};
    local searchLower = string.lower(GD_State.searchText);

    for i = 1, table.getn(book.records) do
        local rec = book.records[i];

        -- 类型筛选
        if GD_State.filterType ~= "all" and rec.type ~= GD_State.filterType then
            -- 跳过不匹配的类型
        else
            -- 关键词搜索
            if searchLower == "" then
                table.insert(records, rec);
            else
                local titleLower = string.lower(rec.title or "");
                local contentLower = string.lower(rec.content or "");
                if string.find(titleLower, searchLower, 1, true)
                    or string.find(contentLower, searchLower, 1, true) then
                    table.insert(records, rec);
                end
            end
        end
    end

    -- 排序
    if GD_State.sortOrder == "newest" then
        table.sort(records, function(a, b)
            return (a.createTime or "") > (b.createTime or "");
        end);
    else
        table.sort(records, function(a, b)
            return (a.createTime or "") < (b.createTime or "");
        end);
    end

    GD_State.filteredRecords = records;

    -- 调整页码
    local totalPages = math.ceil(GD_Utils:ArraySize(records) / GD_CONFIG.RECORDS_PER_PAGE);
    if totalPages == 0 then totalPages = 1; end
    if GD_State.currentPage > totalPages then
        GD_State.currentPage = totalPages;
    end
end

-- 设置搜索关键词
function GD_SetSearchText(text)
    GD_State.searchText = text or "";
    GD_State.currentPage = 1;
    GD_RefreshFilteredRecords();
    GD_RefreshRecordList();
    GD_RefreshPagination();
    GD_RefreshStatistics();
end

-- 设置筛选类型
function GD_SetFilterType(filterType)
    GD_State.filterType = filterType;
    GD_State.currentPage = 1;
    GD_RefreshFilteredRecords();
    GD_RefreshRecordList();
    GD_RefreshPagination();
    GD_RefreshStatistics();
    GD_RefreshFilterButtons();
end

-- 切换排序方式
function GD_ToggleSortOrder()
    if GD_State.sortOrder == "newest" then
        GD_State.sortOrder = "oldest";
    else
        GD_State.sortOrder = "newest";
    end
    GD_RefreshFilteredRecords();
    GD_RefreshRecordList();
    GD_RefreshSortButton();
end

------------------------------------------------------------
-- UI 刷新函数
------------------------------------------------------------

-- 刷新整个UI
function GD_RefreshUI()
    GD_RefreshBookDropdown();
    -- GD_RefreshFilteredRecords is called by individual refresh functions as needed
    -- but we call it once here to ensure consistency
    GD_RefreshFilteredRecords();
    GD_RefreshRecordList();
    GD_RefreshPagination();
    GD_RefreshContentPanel();
    GD_RefreshStatistics();
    GD_RefreshFilterButtons();
    GD_RefreshSortButton();
    GD_RefreshBookButtons();
end

-- 刷新日记本下拉菜单
function GD_RefreshBookDropdown()
    local dropDown = GD_Utils:GetFrame("GD_BookDropDown");
    if not dropDown then return; end

   -- UIDropDownMenu_Initialize(dropDown, GD_BookDropDown_Initialize);
    -- 1.12标准写法：将初始化函数绑定到框架上
    dropDown.initialize = GD_BookDropDown_Initialize;
    UIDropDownMenu_Initialize(dropDown);

    if GD_State.currentBook then
        UIDropDownMenu_SetText(GD_State.currentBook, dropDown);
    else
        UIDropDownMenu_SetText("请选择日记本", dropDown);
    end
end






-- 下拉菜单初始化函数
function GD_BookDropDown_Initialize()
    local info = {};

    -- "新建日记本" 选项
    info.text = "|cFF00FF00+ 新建日记本...|r";
    info.notCheckable = 1;
    info.func = function()
        StaticPopup_Show("GD_NEW_BOOK");
    end;
    UIDropDownMenu_AddButton(info);

    -- 各日记本选项
    local names = GD_GetBookNames();
    for i = 1, table.getn(names) do
        local name = names[i]; -- ★ 关键：保存当前日记本名称到局部变量
        info = {};
        info.text = name;
        info.value = name;
        info.checked = (name == GD_State.currentBook);
        info.func = function()
            GD_SelectBook(name); -- 使用局部变量 name
            -- 更新下拉菜单显示文本
            UIDropDownMenu_SetText(name, GD_Utils:GetFrame("GD_BookDropDown")); 
        end;
        UIDropDownMenu_AddButton(info);
    end
end

-- 刷新记录列表
function GD_RefreshRecordList()
    local records = GD_State.filteredRecords;
    local perPage = GD_CONFIG.RECORDS_PER_PAGE;
    local startIdx = (GD_State.currentPage - 1) * perPage + 1;

    for i = 1, perPage do
        local btn = GD_Utils:GetFrame("GD_RecordButton" .. i);
        if not btn then return; end

        local recordIdx = startIdx + i - 1;
        local record = records[recordIdx];

        local typeText = GD_Utils:GetFrame(btn:GetName() .. "Type");
        local titleText = GD_Utils:GetFrame(btn:GetName() .. "Title");
        local timeText = GD_Utils:GetFrame(btn:GetName() .. "Time");
        local selectedTex = GD_Utils:GetFrame(btn:GetName() .. "SelectedBg");

        if record then
            btn:Show();
            btn:SetID(recordIdx);

            -- 类型标记
            if record.type == GD_CONFIG.TYPE_PITFALL then
                typeText:SetText(GD_CONFIG.COLOR_PITFALL .. "[坑]|r");
                typeText:SetTextColor(GD_CONFIG.RGB_PITFALL.r, GD_CONFIG.RGB_PITFALL.g, GD_CONFIG.RGB_PITFALL.b);
            else
                typeText:SetText(GD_CONFIG.COLOR_FUN .. "[趣]|r");
                typeText:SetTextColor(GD_CONFIG.RGB_FUN.r, GD_CONFIG.RGB_FUN.g, GD_CONFIG.RGB_FUN.b);
            end

            -- 标题
            titleText:SetText(GD_Utils:Truncate(record.title or "无标题", 18));

            -- 时间
            timeText:SetText(GD_Utils:FormatTimestampShort(record.createTime));

            -- 选中高亮
            if record.id == GD_State.selectedRecordId then
                if selectedTex then selectedTex:Show(); end
            else
                if selectedTex then selectedTex:Hide(); end
            end
        else
            btn:Hide();
            if selectedTex then selectedTex:Hide(); end
        end
    end
end

-- 刷新分页
function GD_RefreshPagination()
    local totalRecords = GD_Utils:ArraySize(GD_State.filteredRecords);
    local totalPages = math.ceil(totalRecords / GD_CONFIG.RECORDS_PER_PAGE);
    if totalPages == 0 then totalPages = 1; end

    local pageText = GD_Utils:GetFrame("GD_PageText");
    if pageText then
        pageText:SetText("第 " .. GD_State.currentPage .. "/" .. totalPages .. " 页");
    end

    local prevBtn = GD_Utils:GetFrame("GD_PrevPageBtn");
    local nextBtn = GD_Utils:GetFrame("GD_NextPageBtn");

    if prevBtn then
        if GD_State.currentPage <= 1 then
            prevBtn:Disable();
        else
            prevBtn:Enable();
        end
    end

    if nextBtn then
        if GD_State.currentPage >= totalPages then
            nextBtn:Disable();
        else
            nextBtn:Enable();
        end
    end
end

-- 刷新内容面板（右侧）
function GD_RefreshContentPanel()
    local record = GD_GetSelectedRecord();

    local titleEdit = GD_Utils:GetFrame("GD_TitleEditBox");
    local contentEdit = GD_Utils:GetFrame("GD_ContentEditBox");
    local metaText = GD_Utils:GetFrame("GD_MetaDataText");
    local noRecordText = GD_Utils:GetFrame("GD_NoRecordText");
    local saveBtn = GD_Utils:GetFrame("GD_SaveBtn");
    local deleteBtn = GD_Utils:GetFrame("GD_DeleteBtn");
    local exportRecBtn = GD_Utils:GetFrame("GD_ExportRecordBtn");

    if record then
        -- 显示记录详情
        if titleEdit then
            titleEdit:SetText(record.title or "");
        end
        if contentEdit then
            contentEdit:SetText(record.content or "");
        end

        -- 设置类型按钮状态
        GD_SetTypeButtons(record.type);

        -- 元数据,
        if metaText then
            local meta = "";
            meta = meta .. "角色: " .. (record.charName or "未知")
                .. "  种族: " .. (record.charRace or "未知")
                .. "  职业: " .. (record.charClass or "未知")
                .. "\n等级: " .. tostring(record.charLevel or 0)
                .. "  区域: " .. (record.zone or "未知");
            if record.subZone and record.subZone ~= "" then
                meta = meta .. " (" .. record.subZone .. ")";
            end
            meta = meta .. "  坐标: " .. GD_Utils:FormatCoords(record.posX, record.posY);
            -- meta = meta .. "\n记录时间: " .. GD_Utils:FormatTimestamp(record.createTime)
            --     .. "  游戏时间: " .. (record.gameTime or "未知");
            -- if record.modifyTime and record.modifyTime ~= record.createTime then
            --     meta = meta .. "  修改时间: " .. GD_Utils:FormatTimestamp(record.modifyTime);
            -- end
            meta = meta .. "\n记录时间: " .. GD_Utils:FormatTimestamp(record.createTime);
            metaText:SetText(GD_CONFIG.COLOR_GOLD .. meta .. "|r");
        end

        -- 隐藏"无记录"提示
        if noRecordText then noRecordText:Hide(); end

        -- 启用操作按钮
        if saveBtn then saveBtn:Enable(); end
        if deleteBtn then deleteBtn:Enable(); end
        if exportRecBtn then exportRecBtn:Enable(); end
    else
        -- 无选中记录
        if titleEdit then titleEdit:SetText(""); end
        if contentEdit then contentEdit:SetText(""); end
        if metaText then metaText:SetText(""); end
        GD_SetTypeButtons(nil);

        if noRecordText then noRecordText:Show(); end

        if saveBtn then saveBtn:Enable(); end  -- 新建时仍可用
        if deleteBtn then deleteBtn:Disable(); end
        if exportRecBtn then exportRecBtn:Disable(); end
    end
end

-- 设置类型按钮状态
function GD_SetTypeButtons(recType)
    local pitfallBtn = GD_Utils:GetFrame("GD_TypePitfallBtn");
    local funBtn = GD_Utils:GetFrame("GD_TypeFunBtn");

    if not pitfallBtn or not funBtn then return; end

    if recType == GD_CONFIG.TYPE_PITFALL then
        pitfallBtn:SetChecked(1);
        funBtn:SetChecked(nil);
    elseif recType == GD_CONFIG.TYPE_FUN then
        pitfallBtn:SetChecked(nil);
        funBtn:SetChecked(1);
    else
        pitfallBtn:SetChecked(nil);
        funBtn:SetChecked(nil);
    end
end

-- 获取当前选中的类型
function GD_GetSelectedType()
    local pitfallBtn = GD_Utils:GetFrame("GD_TypePitfallBtn");
    local funBtn = GD_Utils:GetFrame("GD_TypeFunBtn");

    if pitfallBtn and pitfallBtn:GetChecked() then
        return GD_CONFIG.TYPE_PITFALL;
    elseif funBtn and funBtn:GetChecked() then
        return GD_CONFIG.TYPE_FUN;
    end
    return nil;
end

-- 刷新统计信息
function GD_RefreshStatistics()
    --DEFAULT_CHAT_FRAME:AddMessage("刷新统计信息");
    local statsText = GD_Utils:GetFrame("GD_StatsText");
    if not statsText then return; end

    if not GD_State.currentBook then
        statsText:SetText("暂无日记本");
        return;
    end

    local book = GameDiaryDB.books[GD_State.currentBook];
    if not book or not book.records then
        statsText:SetText("暂无记录");
        return;
    end

    local total = table.getn(book.records);
    local pitfallCount = 0;
    local funCount = 0;
    local zones = {};

    for i = 1, total do
        local rec = book.records[i];
        if rec.type == GD_CONFIG.TYPE_PITFALL then
            pitfallCount = pitfallCount + 1;
        elseif rec.type == GD_CONFIG.TYPE_FUN then
            funCount = funCount + 1;
        end
        if rec.zone and rec.zone ~= "" and rec.zone ~= "未知" then
            zones[rec.zone] = true;
        end
    end

    local zoneCount = 0;
    for _ in pairs(zones) do
        zoneCount = zoneCount + 1;
    end

    local stats = "共 " .. total .. " 条记录"
        .. "  |  " .. GD_CONFIG.COLOR_PITFALL .. "坑点 " .. pitfallCount .. "|r"
        .. "  |  " .. GD_CONFIG.COLOR_FUN .. "趣事 " .. funCount .. "|r"
        .. "  |  涵盖 " .. zoneCount .. " 个区域";

    statsText:SetText(stats);
end

-- 刷新筛选按钮
function GD_RefreshFilterButtons()
    local allBtn = GD_Utils:GetFrame("GD_FilterAllBtn");
    local pitfallBtn = GD_Utils:GetFrame("GD_FilterPitfallBtn");
    local funBtn = GD_Utils:GetFrame("GD_FilterFunBtn");

    if allBtn then
        if GD_State.filterType == "all" then
            allBtn:LockHighlight();
        else
            allBtn:UnlockHighlight();
        end
    end
    if pitfallBtn then
        if GD_State.filterType == "pitfall" then
            pitfallBtn:LockHighlight();
        else
            pitfallBtn:UnlockHighlight();
        end
    end
    if funBtn then
        if GD_State.filterType == "fun" then
            funBtn:LockHighlight();
        else
            funBtn:UnlockHighlight();
        end
    end
end

-- 刷新排序按钮
function GD_RefreshSortButton()
    local sortBtn = GD_Utils:GetFrame("GD_SortBtn");
    if not sortBtn then return; end

    local sortText = GD_Utils:GetFrame("GD_SortBtnText");
    if sortText then
        if GD_State.sortOrder == "newest" then
            sortText:SetText("最新优先");
        else
            sortText:SetText("最早优先");
        end
    end
end

-- 刷新日记本管理按钮
function GD_RefreshBookButtons()
    local renameBtn = GD_Utils:GetFrame("GD_RenameBookBtn");
    local deleteBookBtn = GD_Utils:GetFrame("GD_DeleteBookBtn");

    if renameBtn then
        if GD_State.currentBook then
            renameBtn:Enable();
        else
            renameBtn:Disable();
        end
    end

    if deleteBookBtn then
        if GD_State.currentBook then
            deleteBookBtn:Enable();
        else
            deleteBookBtn:Disable();
        end
    end
end

------------------------------------------------------------
-- 事件处理
------------------------------------------------------------

-- 主帧 OnLoad
function GD_OnLoad()

    GD_RegisterStaticPopups();
    -- 注册事件
    this:RegisterEvent("ADDON_LOADED");
    this:RegisterEvent("PLAYER_LOGIN");

    -- 注册拖拽
    this:RegisterForDrag("LeftButton");
    this:SetMovable(true);
    this:SetClampedToScreen(true);

    -- 注册斜杠命令
    SlashCmdList["GAMEDIARY"] = GD_SlashCommand;
    SLASH_GAMEDIARY1 = "/gd";
    SLASH_GAMEDIARY2 = "/gamediary";
    SLASH_GAMEDIARY3 = "/日记";
end

-- 主帧 OnEvent
function GD_OnEvent(event)
    if event == "ADDON_LOADED" then
        if arg1 == "GameDiary" then
            GD_InitDB();
        end
    elseif event == "PLAYER_LOGIN" then
        GD_InitUI();
    end
end

-- 初始化UI
function GD_InitUI()
    -- 初始化下拉菜单
    local dropDown = GD_Utils:GetFrame("GD_BookDropDown");
    if dropDown then
        UIDropDownMenu_SetWidth(160, dropDown);
        UIDropDownMenu_SetButtonWidth(24, dropDown);
    end

    -- 刷新UI
    GD_RefreshUI();

    -- 初始化小地图按钮
    if GD_InitMinimapButton then
        GD_InitMinimapButton();
    end

end

-- 斜杠命令处理
function GD_SlashCommand(msg)
    if not msg or msg == "" then
        -- 切换主界面显示
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
    else
        msg = string.lower(msg);
        if msg == "help" then
            DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_GOLD .. "===== 游戏日记本 帮助 =====|r");
            DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_WHITE .. "/gd - 打开/关闭日记本|r");
            DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_WHITE .. "/gd help - 显示帮助信息|r");
            DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_WHITE .. "/gd new <名称> - 创建新日记本|r");
            DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_WHITE .. "/gd delete <名称> - 删除日记本|r");
        elseif string.sub(msg, 1, 4) == "new " then
            local name = string.sub(msg, 5);
            GD_CreateBook(name);
        elseif string.sub(msg, 1, 7) == "delete " then
            local name = string.sub(msg, 8);
            StaticPopupDialogs["GD_DELETE_BOOK_CMD"] = {
                text = "确定要删除日记本「" .. name .. "」吗？\n此操作不可撤销！",
                button1 = "确定",
                button2 = "取消",
                OnAccept = function()
                    GD_DeleteBook(name);
                end,
                timeout = 0,
                whileDead = 1,
                hideOnEscape = 1,
            };
            StaticPopup_Show("GD_DELETE_BOOK_CMD");
        end
    end
end

------------------------------------------------------------
-- 按钮事件处理
------------------------------------------------------------

-- 记录列表项点击
function GD_OnRecordClick(index)
    local records = GD_State.filteredRecords;
    if not records or not records[index] then return; end

    local record = records[index];
    GD_State.selectedRecordId = record.id;

    PlaySound("igQuestListSelect");
    GD_RefreshRecordList();
    GD_RefreshContentPanel();
end

-- 新建记录
function GD_OnNewRecord()
    GD_State.selectedRecordId = nil;
    GD_SetTypeButtons(nil);

    local titleEdit = GD_Utils:GetFrame("GD_TitleEditBox");
    local contentEdit = GD_Utils:GetFrame("GD_ContentEditBox");
    local metaText = GD_Utils:GetFrame("GD_MetaDataText");
    local noRecordText = GD_Utils:GetFrame("GD_NoRecordText");

    if titleEdit then titleEdit:SetText(""); end
    if contentEdit then contentEdit:SetText(""); end
    if metaText then metaText:SetText("新建记录 - 自动记录当前角色和位置信息"); end
    if noRecordText then noRecordText:Hide(); end

    if titleEdit then titleEdit:SetFocus(); end

    -- 取消列表选中
    for i = 1, GD_CONFIG.RECORDS_PER_PAGE do
        local btn = GD_Utils:GetFrame("GD_RecordButton" .. i);
        if btn then
            local selectedTex = GD_Utils:GetFrame(btn:GetName() .. "SelectedBg");
            if selectedTex then selectedTex:Hide(); end
        end
    end
end

-- 保存记录
function GD_OnSave()
    local recType = GD_GetSelectedType();
    local titleEdit = GD_Utils:GetFrame("GD_TitleEditBox");
    local contentEdit = GD_Utils:GetFrame("GD_ContentEditBox");

    if not recType then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 请选择记录类型（坑点/趣事）！|r");
        return;
    end

    local title = titleEdit and titleEdit:GetText() or "";
    title = string.gsub(title, "^%s*(.-)%s*$", "%1");
    if title == "" then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 请填写标题！|r");
        return;
    end

    local content = contentEdit and contentEdit:GetText() or "";

    if GD_State.selectedRecordId then
        -- 更新现有记录
        GD_UpdateRecord(GD_State.selectedRecordId, recType, title, content);
    else
        -- 新增记录
        GD_AddRecord(recType, title, content);
    end
end

-- 删除记录（带确认）
function GD_OnDeleteRecord()
    if not GD_State.selectedRecordId then return; end

    local record = GD_GetSelectedRecord();
    if not record then return; end

    StaticPopupDialogs["GD_DELETE_RECORD"] = {
        text = "确定要删除这条记录吗？\n「" .. (record.title or "无标题") .. "」\n此操作不可撤销！",
        button1 = "确定",
        button2 = "取消",
        OnAccept = function()
            GD_DeleteRecord(GD_State.selectedRecordId);
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    };
    StaticPopup_Show("GD_DELETE_RECORD");
end

-- 翻页
function GD_OnPrevPage()
    if GD_State.currentPage > 1 then
        GD_State.currentPage = GD_State.currentPage - 1;
        PlaySound(GD_CONFIG.SOUND_PAGE_TURN);
        GD_RefreshRecordList();
        GD_RefreshPagination();
    end
end

function GD_OnNextPage()
    local totalPages = math.ceil(GD_Utils:ArraySize(GD_State.filteredRecords) / GD_CONFIG.RECORDS_PER_PAGE);
    if GD_State.currentPage < totalPages then
        GD_State.currentPage = GD_State.currentPage + 1;
        PlaySound(GD_CONFIG.SOUND_PAGE_TURN);
        GD_RefreshRecordList();
        GD_RefreshPagination();
    end
end

------------------------------------------------------------
-- 导入导出
------------------------------------------------------------



-- 导出整本日记
function GD_OnExportAll()
    if not GD_State.currentBook then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 请先选择一个日记本！|r");
        return;
    end

    local book = GameDiaryDB.books[GD_State.currentBook];
    if not book or table.getn(book.records) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 当前日记本没有记录！|r");
        return;
    end

    local segments = GD_Utils:EncodeForExport(GD_State.currentBook, book.records);
    local fullText = table.concat(segments, "\n");
    GD_ShowExportFrame("导出日记本「" .. GD_State.currentBook .. "」", fullText);
end

-- 导出当前选中记录
function GD_OnExportRecord()
    local record = GD_GetSelectedRecord();
    if not record then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 请先选择一条记录！|r");
        return;
    end

    local segments = GD_Utils:EncodeForExport(GD_State.currentBook, { record });
    local fullText = table.concat(segments, "\n");
    GD_ShowExportFrame("导出记录「" .. (record.title or "无标题") .. "」", fullText);
end

-- 显示导出框

function GD_ShowExportFrame(title, text)
    local frame = GD_Utils:GetFrame("GD_ExportFrame");
    if not frame then return; end

    local titleText = GD_Utils:GetFrame("GD_ExportFrameTitle");
    local editBox = GD_Utils:GetFrame("GD_ExportFrameEditBox");
    local scrollFrame = GD_Utils:GetFrame("GD_ExportScrollFrame");

    if titleText then
        titleText:SetText(title);
    end
    if editBox then
        editBox:SetText(text);
        if scrollFrame then
            scrollFrame:SetVerticalScroll(0); -- 回到顶部
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Error: GD_ExportFrameEditBox not found!");
    end
    
    frame:Show();
end

-- 关闭导出框


function GD_CloseExportFrame()
    local frame = GD_Utils:GetFrame("GD_ExportFrame");
    if frame then frame:Hide(); end
    local editBox = GD_Utils:GetFrame("GD_ExportFrameEditBox");
    if editBox then editBox:SetText(""); end  --  释放内存
end

-- 显示导入框
function GD_OnImport()
    local frame = GD_Utils:GetFrame("GD_ImportFrame");
    if not frame then return; end

    local editBox = GD_Utils:GetFrame("GD_ImportFrameEditBox");
    local scrollFrame = GD_Utils:GetFrame("GD_ImportScrollFrame");

    if editBox then
        editBox:SetText("");
    end
    if scrollFrame then
         scrollFrame:SetVerticalScroll(0); -- 回到顶部
    end

    frame:Show();
end

-- 关闭导入框
function GD_CloseImportFrame()
    local frame = GD_Utils:GetFrame("GD_ImportFrame");
    if frame then frame:Hide(); end
    local editBox = GD_Utils:GetFrame("GD_ImportFrameEditBox");
    if editBox then editBox:SetText(""); end  --  释放内存
end

-- 执行导入
function GD_DoImport()
    local editBox = GD_Utils:GetFrame("GD_ImportFrameEditBox");
    if not editBox then return; end

    local text = editBox:GetText();
    if not text or text == "" then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 请粘贴导入数据！|r");
        return;
    end

    local success, result1, result2 = GD_Utils:DecodeFromImport(text);

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 导入失败: " .. tostring(result1) .. "|r");
        return;
    end

    local bookName = result1;
    local records = result2;

    if not bookName or table.getn(records) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage(GD_CONFIG.COLOR_PITFALL .. "[游戏日记本] 导入数据为空！|r");
        return;
    end

    -- 处理导入冲突
    if GameDiaryDB.books[bookName] then
        -- 日记本已存在，追加记录
        local existingBook = GameDiaryDB.books[bookName];
        local addedCount = 0;
        local skippedCount = 0;

        for i = 1, table.getn(records) do
            local rec = records[i];
            -- 检查是否重复（根据标题+创建时间判断）
            local isDuplicate = false;
            for j = 1, table.getn(existingBook.records) do
                local existing = existingBook.records[j];
                if existing.title == rec.title and existing.createTime == rec.createTime then
                    isDuplicate = true;
                    break;
                end
            end

            if not isDuplicate then
                -- 生成新ID避免冲突
                rec.id = GD_Utils:GenerateId();
                table.insert(existingBook.records, rec);
                addedCount = addedCount + 1;
            else
                skippedCount = skippedCount + 1;
            end
        end

        DEFAULT_CHAT_FRAME:AddMessage(
            GD_CONFIG.COLOR_FUN .. "[游戏日记本] 导入成功！追加 " .. addedCount .. " 条记录到「" .. bookName .. "」"
            .. (skippedCount > 0 and ("，跳过 " .. skippedCount .. " 条重复记录") or "") .. "|r"
        );
    else
        -- 创建新日记本
        GameDiaryDB.books[bookName] = {
            records = records,
            createTime = GD_Utils:GetTimestamp(),
        };

        DEFAULT_CHAT_FRAME:AddMessage(
            GD_CONFIG.COLOR_FUN .. "[游戏日记本] 导入成功！创建日记本「" .. bookName .. "」，共 " .. table.getn(records) .. " 条记录。|r"
        );
    end

    -- 切换到导入的日记本
    GD_SelectBook(bookName);
    GD_CloseImportFrame();
end

------------------------------------------------------------
-- StaticPopup 对话框注册
------------------------------------------------------------
function GD_RegisterStaticPopups()
    -- 新建日记本
    StaticPopupDialogs["GD_NEW_BOOK"] = {
        text = "请输入新日记本的名称：",
        button1 = "创建",
        button2 = "取消",
        hasEditBox = 1,
        maxLetters = GD_CONFIG.MAX_BOOK_NAME_LENGTH,
        OnAccept = function()
            local editBox = getglobal(this:GetParent():GetName() .. "EditBox");
            local name = editBox:GetText();
            if name and name ~= "" then
                GD_CreateBook(name);
            end
        end,
        EditBoxOnTextChanged = function()
            local editBox = this;
            local btn = getglobal(editBox:GetParent():GetName() .. "Button1");
            if editBox:GetText() == "" then
                btn:Disable();
            else
                btn:Enable();
            end
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
    };

    -- 重命名日记本
    StaticPopupDialogs["GD_RENAME_BOOK"] = {
        text = "请输入新的日记本名称：",
        button1 = "确定",
        button2 = "取消",
        hasEditBox = 1,
        maxLetters = GD_CONFIG.MAX_BOOK_NAME_LENGTH,
        OnAccept = function()
            local editBox = getglobal(this:GetParent():GetName() .. "EditBox");
            local newName = editBox:GetText();
            if newName and newName ~= "" and GD_State.currentBook then
                GD_RenameBook(GD_State.currentBook, newName);
            end
        end,
        EditBoxOnTextChanged = function()
            local editBox = this;
            local btn = getglobal(editBox:GetParent():GetName() .. "Button1");
            if editBox:GetText() == "" then
                btn:Disable();
            else
                btn:Enable();
            end
        end,
        OnShow = function()
            local editBox = getglobal(this:GetName() .. "EditBox");
            if editBox and GD_State.currentBook then
                editBox:SetText(GD_State.currentBook);
                editBox:HighlightText();
            end
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
    };

    -- 删除日记本
    StaticPopupDialogs["GD_DELETE_BOOK"] = {
        text = "",
        button1 = "确定",
        button2 = "取消",
        OnAccept = function()
            if GD_State.currentBook then
                GD_DeleteBook(GD_State.currentBook);
            end
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
    };

    -- 删除记录（在GD_OnDeleteRecord中动态设置text）
    StaticPopupDialogs["GD_DELETE_RECORD"] = {
        text = "",
        button1 = "确定",
        button2 = "取消",
        OnAccept = function()
            if GD_State.selectedRecordId then
                GD_DeleteRecord(GD_State.selectedRecordId);
            end
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
        preferredIndex = 3,
    };
end

-- 显示删除日记本确认
function GD_OnDeleteBook()
    if not GD_State.currentBook then return; end

    StaticPopupDialogs["GD_DELETE_BOOK"].text =
        "确定要删除日记本「" .. GD_State.currentBook .. "」吗？\n其中的所有记录将一并删除！\n此操作不可撤销！";
    StaticPopup_Show("GD_DELETE_BOOK");
end

-- 显示重命名日记本对话框
function GD_OnRenameBook()
    if not GD_State.currentBook then return; end
    StaticPopup_Show("GD_RENAME_BOOK");
end

------------------------------------------------------------
-- 主帧显示/隐藏
------------------------------------------------------------
function GD_OnShow()
    --GD_RegisterStaticPopups();
    GD_RefreshUI();
    PlaySound(GD_CONFIG.SOUND_OPEN);
end

function GD_OnHide()
    PlaySound(GD_CONFIG.SOUND_CLOSE);
end

-- 搜索框文本变化
function GD_SearchBox_OnTextChanged()
    local editBox = this;
    local text = editBox:GetText() or "";
    GD_SetSearchText(text);

    -- 控制占位符显示
    local placeholder = GD_Utils:GetFrame("GD_SearchBoxPlaceholder");
    if placeholder then
        if text == "" then
            placeholder:Show();
        else
            placeholder:Hide();
        end
    end
end

-- 导出框EditBox获得焦点时自动全选
function GD_ExportEditBox_OnEditFocusGained()
    this:HighlightText();
end

-- 内容EditBox鼠标滚轮
function GD_ContentEditBox_OnMouseWheel(scroll)
    if scroll > 0 then
        this:ScrollUp();
    else
        this:ScrollDown();
    end
end


