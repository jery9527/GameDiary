
-- GameDiary_Config.lua
-- 插件配置常量


GD_CONFIG = {
    -- ===== 版本信息 =====
    VERSION = "1.0.0",
    DATA_VERSION = 1,

    -- ===== 颜色定义 =====
    COLOR_PITFALL = "|cFFFF4444",     -- 坑点 - 红色
    COLOR_FUN = "|cFF44FF44",         -- 趣事 - 绿色
    COLOR_GOLD = "|cFFFFD700",        -- 金色标题
    COLOR_WHITE = "|cFFFFFFFF",       -- 白色
    COLOR_GRAY = "|cFFAAAAAA",        -- 灰色
    COLOR_YELLOW = "|cFFFFFF00",      -- 黄色
    COLOR_HIGHLIGHT = "|cFFFF8C00",   -- 橙色高亮
    COLOR_DARK = "|cFF333333",        -- 深色
    COLOR_CYAN = "|cFF00FFFF",        -- 青色

    -- ===== 原始RGB颜色（用于SetTextColor） =====
    RGB_PITFALL = { r = 1.0, g = 0.27, b = 0.27 },
    RGB_FUN = { r = 0.27, g = 1.0, b = 0.27 },
    RGB_GOLD = { r = 1.0, g = 0.84, b = 0.0 },
    RGB_WHITE = { r = 1.0, g = 1.0, b = 1.0 },
    RGB_GRAY = { r = 0.67, g = 0.67, b = 0.67 },
    RGB_HIGHLIGHT = { r = 1.0, g = 0.55, b = 0.0 },
    RGB_SELECTED_BG = { r = 0.3, g = 0.2, b = 0.0, a = 0.5 },
    RGB_NORMAL_BG = { r = 0.0, g = 0.0, b = 0.0, a = 0.3 },

    -- ===== UI 尺寸 =====
    MAIN_WIDTH = 760,
    MAIN_HEIGHT = 560,
    LEFT_PANEL_WIDTH = 290,
    RIGHT_PANEL_WIDTH = 440,
    RECORDS_PER_PAGE = 6,
    RECORD_BUTTON_HEIGHT = 34,

    -- ===== 输入限制 =====
    MAX_TITLE_LENGTH = 100,
    MAX_CONTENT_LENGTH = 2000,
    MAX_BOOK_NAME_LENGTH = 30,
    MAX_SEARCH_LENGTH = 50,

    -- ===== 导出设置 =====
    EXPORT_SEGMENT_LENGTH = 200,

    -- ===== 小地图按钮默认位置 =====
    MINIMAP_DEFAULT_ANGLE = 225,
    MINIMAP_DEFAULT_RADIUS = 80,

    -- ===== 音效 =====
    SOUND_OPEN = "igQuestLogOpen",
    SOUND_CLOSE = "igQuestLogClose",
    SOUND_PAGE_TURN = "igBookPageTurn",
    SOUND_SAVE = "TellMessage",
    SOUND_DELETE = "igAbilityIconDrop",

    -- ===== 分隔符（用于序列化） =====
    FIELD_SEP = "\x1F",   -- 字段分隔符（Unit Separator）
    RECORD_SEP = "\x1E",  -- 记录分隔符（Record Separator）

    -- ===== 记录类型 =====
    TYPE_PITFALL = "pitfall",
    TYPE_FUN = "fun",
    TYPE_LABELS = {
        pitfall = "坑",
        fun = "趣",
    },
};
