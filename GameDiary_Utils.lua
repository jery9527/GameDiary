
-- GameDiary_Utils.lua
-- 工具函数库：Base64编解码、序列化、时间格式化、字符串处理等

GD_Utils = {};

------------------------------------------------------------
-- 唯一ID生成
------------------------------------------------------------
function GD_Utils:GenerateId()
    local t = date("*t");
    return string.format("%04d%02d%02d%02d%02d%02d",
        t.year, t.month, t.day, t.hour, t.min, t.sec)
        .. math.random(1000, 9999);
end

------------------------------------------------------------
-- 时间戳格式化
-- 输入: "20250315143000" → 输出: "2025/03/15 14:30"
------------------------------------------------------------
function GD_Utils:FormatTimestamp(ts)
    if not ts or ts == "" then return "未知"; end
    local y = string.sub(ts, 1, 4);
    local m = string.sub(ts, 5, 6);
    local d = string.sub(ts, 7, 8);
    local H = string.sub(ts, 9, 10);
    local M = string.sub(ts, 11, 12);
    if y and m and d and H and M then
        return y .. "/" .. m .. "/" .. d .. " " .. H .. ":" .. M;
    end
    return ts;
end

------------------------------------------------------------
-- 短时间格式化（用于列表显示）
-- 输入: "20250315143000" → 输出: "03/15 14:30"
------------------------------------------------------------
function GD_Utils:FormatTimestampShort(ts)
    if not ts or ts == "" then return ""; end
    local m = string.sub(ts, 5, 6);
    local d = string.sub(ts, 7, 8);
    local H = string.sub(ts, 9, 10);
    local M = string.sub(ts, 11, 12);
    if m and d and H and M then
        return m .. "/" .. d .. " " .. H .. ":" .. M;
    end
    return "";
end

------------------------------------------------------------
-- 获取当前时间戳字符串 "YYYYMMDDHHmmss"
------------------------------------------------------------
function GD_Utils:GetTimestamp()
    local t = date("*t");
    return string.format("%04d%02d%02d%02d%02d%02d",
        t.year, t.month, t.day, t.hour, t.min, t.sec);
end

------------------------------------------------------------
-- 获取游戏内时间 "HH:MM"
------------------------------------------------------------
function GD_Utils:GetGameTime()
    local hour, minute = GetGameTime();
    return string.format("%02d:%02d", hour, minute);
end

------------------------------------------------------------
-- 获取玩家信息
------------------------------------------------------------
function GD_Utils:GetPlayerInfo()
    local name = UnitName("player");
    local race = UnitRace("player");
    local class = UnitClass("player");
    local level = UnitLevel("player");
    local zone = GetRealZoneText();
    local subZone = GetZoneText();
    local posX, posY = GetPlayerMapPosition("player");

    return {
        charName = name or "未知",
        charRace = race or "未知",
        charClass = class or "未知",
        charLevel = level or 0,
        zone = zone or "未知",
        subZone = subZone or "",
        posX = posX or 0,
        posY = posY or 0,
    };
end

------------------------------------------------------------
-- 格式化坐标 (0~1 → 0.0~100.0)
------------------------------------------------------------
function GD_Utils:FormatCoords(x, y)
    if x and y and x > 0 and y > 0 then
        return string.format("%.1f, %.1f", x * 100, y * 100);
    end
    return "未知";
end

------------------------------------------------------------
-- 字符串分割
------------------------------------------------------------
function GD_Utils:Split(str, sep)
    if not str or str == "" then return {}; end
    local parts = {};
    local start = 1;
    local sepLen = string.len(sep);
    while true do
        local pos = string.find(str, sep, start, true);
        if not pos then
            table.insert(parts, string.sub(str, start));
            break;
        end
        table.insert(parts, string.sub(str, start, pos - 1));
        start = pos + sepLen;
    end
    return parts;
end

------------------------------------------------------------
-- 字符串拼接
------------------------------------------------------------
function GD_Utils:Join(parts, sep)
    if not parts or table.getn(parts) == 0 then return ""; end
    local result = parts[1];
    for i = 2, table.getn(parts) do
        result = result .. sep .. parts[i];
    end
    return result;
end

------------------------------------------------------------
-- 简单校验和
------------------------------------------------------------
function GD_Utils:Checksum(str)
    if not str or str == "" then return 0; end
    local sum = 0;
    for i = 1, string.len(str) do
        sum = sum + string.byte(str, i);
        --sum = sum % 2147483647; -- 防止溢出
        sum = math.fmod(sum, 2147483647);
        --sum = sum % 10; -- 防止溢出
    end
    return sum;
end

------------------------------------------------------------
-- Base64 编码
------------------------------------------------------------


-- Base64 字符表
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function GD_Utils:Base64Encode(data)
    if not data or data == "" then return "" end
    local result = {}
    local len = string.len(data)
    local i = 1
    while i <= len do
        -- 取3个字节，不足补0
        local a = string.byte(data, i) or 0
        local b = string.byte(data, i+1) or 0
        local c = string.byte(data, i+2) or 0
        -- 组合成24位整数
        local n = a * 65536 + b * 256 + c
        
        -- 提取6位组 (使用整除和 math.fmod 替代 %)
        local n1 = math.floor(n / 262144)                       -- 高6位
        local n2 = math.floor(math.fmod(n, 262144) / 4096)      -- 次高6位
        local n3 = math.floor(math.fmod(n, 4096) / 64)          -- 次低6位
        local n4 = math.fmod(n, 64)                             -- 低6位
        
        -- 转为字符
        local c1 = string.sub(B64_CHARS, n1+1, n1+1)
        local c2 = string.sub(B64_CHARS, n2+1, n2+1)
        local c3 = string.sub(B64_CHARS, n3+1, n3+1)
        local c4 = string.sub(B64_CHARS, n4+1, n4+1)
        
        -- 末尾填充处理
        if i + 2 > len then
            if i + 1 > len then
                c2 = "="
                c3 = "="
                c4 = "="
            else
                c3 = "="
                c4 = "="
            end
        end
        
        table.insert(result, c1..c2..c3..c4)
        i = i + 3
    end
    return table.concat(result)
end


------------------------------------------------------------
-- Base64 解码
------------------------------------------------------------

function GD_Utils:Base64Decode(data)
    if not data or data == "" then return "" end
    -- 移除非Base64字符
    data = string.gsub(data, "[^"..B64_CHARS.."=]", "")
    local result = {}
    local len = string.len(data)
    local i = 1
    
    local function charToVal(ch)
        if ch == "=" then return 0 end
        local pos = string.find(B64_CHARS, ch, 1, true)
        if not pos then return 0 end
        return pos - 1
    end
    
    while i <= len do
        local c1 = string.sub(data, i, i) or "="
        local c2 = string.sub(data, i+1, i+1) or "="
        local c3 = string.sub(data, i+2, i+2) or "="
        local c4 = string.sub(data, i+3, i+3) or "="
        
        local v1 = charToVal(c1)
        local v2 = charToVal(c2)
        local v3 = charToVal(c3)
        local v4 = charToVal(c4)
        
        -- 重组24位整数
        local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4
        
        -- 提取3个字节 (使用 math.fmod 替代 %)
        local byte1 = math.floor(n / 65536)
        local byte2 = math.floor(math.fmod(n, 65536) / 256)
        local byte3 = math.fmod(n, 256)
        
        local chars = {}
        if c3 == "=" then
            table.insert(chars, string.char(byte1))
        elseif c4 == "=" then
            table.insert(chars, string.char(byte1))
            table.insert(chars, string.char(byte2))
        else
            table.insert(chars, string.char(byte1))
            table.insert(chars, string.char(byte2))
            table.insert(chars, string.char(byte3))
        end
        
        table.insert(result, table.concat(chars))
        i = i + 4
    end
    return table.concat(result)
end





------------------------------------------------------------
-- 序列化一本日记为字符串
-- 格式: bookName \x1E field1 \x1F field2 \x1F ... \x1E ...
------------------------------------------------------------
function GD_Utils:SerializeBook(bookName, records)
    local FS = GD_CONFIG.FIELD_SEP;
    local RS = GD_CONFIG.RECORD_SEP;
    local data = bookName .. RS;

    if records then
        for i = 1, table.getn(records) do
            local rec = records[i];
            local fields = {
                rec.type or "",
                rec.title or "",
                rec.content or "",
                rec.charName or "",
                rec.charRace or "",
                rec.charClass or "",
                tostring(rec.charLevel or ""),
                rec.zone or "",
                rec.subZone or "",
                tostring(rec.posX or ""),
                tostring(rec.posY or ""),
                rec.createTime or "",
                rec.modifyTime or "",
                rec.gameTime or "",
            };
            data = data .. GD_Utils:Join(fields, FS) .. RS;
        end
    end

    return data;
end

------------------------------------------------------------
-- 反序列化字符串为日记数据
-- 返回: bookName, records_array
------------------------------------------------------------
function GD_Utils:DeserializeBook(data)
    if not data or data == "" then return nil, {}; end

    local FS = GD_CONFIG.FIELD_SEP;
    local RS = GD_CONFIG.RECORD_SEP;
    local parts = GD_Utils:Split(data, RS);

    if table.getn(parts) < 1 then return nil, {}; end

    local bookName = parts[1];
    local records = {};

    for i = 2, table.getn(parts) do
        local fields = GD_Utils:Split(parts[i], FS);
        if table.getn(fields) >= 14 then
            table.insert(records, {
                type = fields[1],
                title = fields[2],
                content = fields[3],
                charName = fields[4],
                charRace = fields[5],
                charClass = fields[6],
                charLevel = tonumber(fields[7]) or 0,
                zone = fields[8],
                subZone = fields[9],
                posX = tonumber(fields[10]) or 0,
                posY = tonumber(fields[11]) or 0,
                createTime = fields[12],
                modifyTime = fields[13],
                gameTime = fields[14],
            });
        end
    end

    return bookName, records;
end

------------------------------------------------------------
-- 导出编码：序列化 + Base64 + 校验和
-- 返回: "GD|checksum|base64data"
------------------------------------------------------------

function GD_Utils:EncodeForExport(bookName, records)
    local raw = GD_Utils:SerializeBook(bookName, records);
    local encoded = GD_Utils:Base64Encode(raw);
    local checksum = GD_Utils:Checksum(encoded);
    local maxLen = GD_CONFIG.EXPORT_SEGMENT_LENGTH;
    local segments = {};
    local totalParts = math.ceil(string.len(encoded) / maxLen);
    for i = 1, totalParts do
        local startIdx = (i - 1) * maxLen + 1;
        local endIdx = math.min(i * maxLen, string.len(encoded));
        local chunk = string.sub(encoded, startIdx, endIdx);
        -- 使用 \x1F 作为分隔符
        table.insert(segments, "GD\x1FP\x1F" .. i .. "\x1F" .. totalParts .. "\x1F" .. tostring(checksum) .. "\x1F" .. chunk);
    end
    return segments;
end
------------------------------------------------------------
-- 导入解码：校验 + Base64解码 + 反序列化
-- 返回: success, bookName, records 或 success, errorMsg
------------------------------------------------------------

function GD_Utils:DecodeFromImport(text)
    if not text or text == "" then
        return false, "导入数据为空";
    end

    -- 去除 BOM 头
    if string.sub(text, 1, 3) == "\xEF\xBB\xBF" then
        text = string.sub(text, 4);
    end

    text = string.gsub(text, "^%s*(.-)%s*$", "%1");
    --DEFAULT_CHAT_FRAME:AddMessage("导入数据预览: " .. string.sub(text, 1, 200));

    local lines = GD_Utils:Split(text, "\n");
    local fullBase64 = "";
    local checksum = nil;
    local totalParts = nil;
    local sep = "\x1F";  -- 新分隔符

    for i = 1, table.getn(lines) do
        local line = string.gsub(lines[i], "^%s*(.-)%s*$", "%1");
        if line ~= "" then
            -- 清理颜色代码
            line = string.gsub(line, "|c%x%x%x%x%x%x%x%x", "");
            line = string.gsub(line, "|r", "");

            --DEFAULT_CHAT_FRAME:AddMessage("第" .. i .. "行清理后: " .. string.sub(line, 1, 100));

            -- 尝试新格式 (以 \x1F 分隔)
            local parts = GD_Utils:Split(line, sep);
            if table.getn(parts) == 6 and parts[1] == "GD" and parts[2] == "P" then
                local partNum = tonumber(parts[3]);
                local total = tonumber(parts[4]);
                local chk = tonumber(parts[5]);
                local chunk = parts[6];
                if checksum == nil then
                    checksum = chk;
                    totalParts = total;
                elseif chk ~= checksum then
                    DEFAULT_CHAT_FRAME:AddMessage("警告: 第" .. i .. "行校验码不一致");
                end
                fullBase64 = fullBase64 .. chunk;
                --DEFAULT_CHAT_FRAME:AddMessage("多段追加，当前总长度=" .. string.len(fullBase64));
            else
                -- 尝试旧格式 (以 | 分隔，兼容旧数据)
                local oldParts = GD_Utils:Split(line, "|");
                if table.getn(oldParts) == 6 and oldParts[1] == "GD" and oldParts[2] == "P" then
                    local chk = tonumber(oldParts[5]);
                    local chunk = oldParts[6];
                    if checksum == nil then
                        checksum = chk;
                    end
                    fullBase64 = fullBase64 .. chunk;
                    DEFAULT_CHAT_FRAME:AddMessage("使用旧格式解析，校验码=" .. tostring(chk));
                elseif table.getn(oldParts) == 3 and oldParts[1] == "GD" then
                    checksum = tonumber(oldParts[2]);
                    fullBase64 = oldParts[3];
                    DEFAULT_CHAT_FRAME:AddMessage("识别为单段数据，校验码=" .. tostring(checksum));
                    break;
                else
                    DEFAULT_CHAT_FRAME:AddMessage("第" .. i .. "行格式无法识别，字段数=" .. table.getn(oldParts));
                end
            end
        end
    end

    if fullBase64 == "" then
        DEFAULT_CHAT_FRAME:AddMessage("错误: 未提取到Base64数据");
        return false, "未检测到有效的日记数据（Base64部分为空）";
    end

    if not checksum then
        DEFAULT_CHAT_FRAME:AddMessage("错误: 未提取到校验码");
        return false, "无法获取校验码（未找到有效的校验码字段）";
    end

    local actualChecksum = GD_Utils:Checksum(fullBase64);
    DEFAULT_CHAT_FRAME:AddMessage("校验: 期望=" .. tostring(checksum) .. ", 实际=" .. tostring(actualChecksum));
    if actualChecksum ~= checksum then
        return false, "校验失败，数据可能在传输中损坏（期望 " .. tostring(checksum) .. "，实际 " .. tostring(actualChecksum) .. "）";
    end

    local raw = GD_Utils:Base64Decode(fullBase64);
    if not raw or raw == "" then
        DEFAULT_CHAT_FRAME:AddMessage("错误: Base64解码失败");
        return false, "Base64 解码失败，可能数据不完整或损坏";
    end

    local bookName, records = GD_Utils:DeserializeBook(raw);
    if not bookName then
        DEFAULT_CHAT_FRAME:AddMessage("错误: 反序列化失败");
        return false, "数据解析失败，无法获取日记本名称";
    end

    DEFAULT_CHAT_FRAME:AddMessage("导入解析成功，日记本=" .. bookName .. ", 记录数=" .. table.getn(records));
    return true, bookName, records;
end
------------------------------------------------------------
-- 分段导出（用于聊天框发送）
-- 返回: 字符串数组，每段不超过 EXPORT_SEGMENT_LENGTH
------------------------------------------------------------
function GD_Utils:EncodeForChat(bookName, records)
    local raw = GD_Utils:SerializeBook(bookName, records);
    local encoded = GD_Utils:Base64Encode(raw);
    local checksum = GD_Utils:Checksum(encoded);
    local maxLen = GD_CONFIG.EXPORT_SEGMENT_LENGTH;

    if string.len(encoded) <= maxLen then
        return { "GD|" .. tostring(checksum) .. "|" .. encoded };
    end

    -- 分段
    local segments = {};
    local totalParts = math.ceil(string.len(encoded) / maxLen);
    for i = 1, totalParts do
        local startIdx = (i - 1) * maxLen + 1;
        local endIdx = math.min(i * maxLen, string.len(encoded));
        local chunk = string.sub(encoded, startIdx, endIdx);
        table.insert(segments, "GD|P|" .. i .. "|" .. totalParts .. "|" .. tostring(checksum) .. "|" .. chunk);
    end

    return segments;
end

------------------------------------------------------------
-- 截断字符串（用于列表显示）
------------------------------------------------------------
function GD_Utils:Truncate(str, maxLen)
    if not str then return ""; end
    if string.len(str) <= maxLen then return str; end
    return string.sub(str, 1, maxLen) .. "...";
end

------------------------------------------------------------
-- 转义聊天颜色标记（用于导出文本显示）
------------------------------------------------------------
function GD_Utils:StripColors(str)
    if not str then return ""; end
    str = string.gsub(str, "|c%x%x%x%x%x%x%x%x", "");
    str = string.gsub(str, "|r", "");
    return str;
end

------------------------------------------------------------
-- 表深度复制
------------------------------------------------------------
function GD_Utils:DeepCopy(src)
    if type(src) ~= "table" then return src; end
    local dst = {};
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = GD_Utils:DeepCopy(v);
        else
            dst[k] = v;
        end
    end
    return dst;
end

------------------------------------------------------------
-- 获取表长度（兼容Lua 5.0）
------------------------------------------------------------
function GD_Utils:TableSize(t)
    if not t then return 0; end
    local count = 0;
    for _ in pairs(t) do
        count = count + 1;
    end
    return count;
end

------------------------------------------------------------
-- 按IPairs遍历的表长度
------------------------------------------------------------
function GD_Utils:ArraySize(t)
    if not t then return 0; end
    return table.getn(t);
end

------------------------------------------------------------
-- 在数组中查找元素
------------------------------------------------------------
function GD_Utils:ArrayFind(arr, value, key)
    if not arr then return nil; end
    for i = 1, table.getn(arr) do
        if key then
            if arr[i][key] == value then return i; end
        else
            if arr[i] == value then return i; end
        end
    end
    return nil;
end

------------------------------------------------------------
-- 从数组中删除元素
------------------------------------------------------------
function GD_Utils:ArrayRemove(arr, index)
    if not arr or index < 1 or index > table.getn(arr) then return; end
    table.remove(arr, index);
end

------------------------------------------------------------
-- 安全获取全局帧
------------------------------------------------------------
function GD_Utils:GetFrame(name)
    if not name then return nil; end
    return getglobal(name);
end
