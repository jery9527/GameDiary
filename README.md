# GameDiary
This is a plugin for Turtle WoW 1.18.1. It lets you share all the tricky situations and fun moments you come across while playing. Other players, especially new ones, can learn from these shared experiences and enjoy a better gaming experience.

<img width="1053" height="768" alt="gamediary" src="https://github.com/user-attachments/assets/24c9e8c4-ba3b-41db-b71b-abddd78a5799" />

这是一个乌龟服1.18.1版本的插件，主要就是用来分享游戏过程中遇到的各种坑和有趣的事，还可以分享其他玩家，尤其是新手玩家，可以学习，能有更好的游戏体验。
# 导入字符串
这串字符串就是他人导出的日记字符串，复制后，直接导入即可。字符串形式如下：
```GDx1FPx1F1x1F4x1F51270x1FTFLml6XorrB4MUVmdW54MUbml6XorrDmj5Lku7blvIDlj5Hlrozmr5V4MUYyMDI25bm0NOaciDLml6Uw54K55oiR5LiA5Liq54yO5Lq677yM5a6M5oiQ5LqG5oiR55qE56ys5LiA5Liq6a2U5YW95LiW55WM5o+S5Lu255qE5byA5Y+R5bel5L2c77yM5ZOI5ZOI5ZOI
GDx1FPx1F2x1F4x1F51270x1F44CC5LiN5piv5b6I6Zq+77yM5L2G5Lmf5LiN566A5Y2V77yM5ZyoQUnnmoTluK7liqnkuIvvvIzmiJHlrp7njrDkuobmiJHnmoTmhL/mnJvjgILliqDmsrnllYrvvIHvvIHvvIEKCk5lb29lbu+8jOi/meaYr+aIkeWcqOS5jOm+n+acjeS4reeahExS5ZCN5a2X77yM
GDx1FPx1F3x1F4x1F51270x1F5oiR5ZyoR+acjeOAgngxRk5lb29lbngxRuS6uuexu3gxRueMjuS6ungxRjU3eDFG6I2G5qOY6LC3eDFG6I2G5qOY6LC3eDFGMC4yNjk3MTAxNTMzNDEyOXgxRjAuNzczMzIzNTM1OTE5MTl4MUYyMDI2MDQwMjAwMjM1OXgxRjIwMjYwNDAyMDAyMzU5eDFGMTc6MjN4
GDx1FPx1F4x1F4x1F51270x1FMU==
```
# 详细使用

适用于**魔兽世界乌龟服1.18.1**的游戏日记插件，支持记录游戏中的坑点/趣事、多日记本管理、记录导入导出，还能自动留存角色/位置/时间等信息，方便玩家分享游戏经历、帮助新手避坑。

## 🔧 插件安装
1. 下载插件文件夹`GameDiary`
2. 将文件夹放入乌龟服安装目录：`_classic_era_1_18_1/Interface/AddOns/`
3. 启动游戏，在**角色选择界面**勾选「GameDiary」插件（若提示过期，勾选「加载过期插件」）
4. 进入游戏后，通过小地图按钮或斜杠命令打开插件

## ✨ 核心功能
- 📒 **多日记本管理**：创建/重命名/删除多个日记本，分类记录不同内容
- ✍️ **坑点/趣事双类型记录**：自定义标题+内容，自动记录角色名/种族/职业/等级/当前区域/坐标/时间
- 🔍 **精准筛选搜索**：按类型筛选、关键词搜索、按时间排序（最新/最早）
- 📤📥 **导入导出**：单条记录/整本日记导出为编码文本，支持跨玩家导入分享
- 🗺️ **小地图快捷按钮**：可拖拽调整位置，一键打开/关闭插件
- 📊 **数据统计**：实时显示当前日记本的记录总数、坑点/趣事数量、涵盖游戏区域数

## 📖 详细使用
### 一、打开插件
支持两种方式，任选其一：
1. **小地图按钮**：点击小地图旁的**书本图标**（可鼠标拖拽调整按钮位置）
2. **斜杠命令**：在游戏聊天框输入 `/gd` 或 `/日记` 或 `/gamediary`

### 二、日记本管理
1. **创建日记本**：点击插件顶部「+ 新建日记本...」或「新建」按钮，输入名称即可
2. **切换日记本**：通过顶部下拉菜单，选择已创建的日记本
3. **重命名/删除**：选中日记本后，点击顶部「重命名」「删除」按钮（删除不可逆，需确认）

### 三、记录增删改查
#### 1. 新建记录
1. 点击插件右侧「新建」按钮
2. 选择记录类型：✅**坑点**（红色）/✅**趣事**（绿色）（必须选其一）
3. 填写**标题**（必填）+**内容**（选填）
4. 点击「保存」，插件自动留存当前角色、位置、时间等元数据

#### 2. 查看/编辑记录
1. 在左侧列表点击要查看的记录，右侧将显示**完整内容+元数据**（角色/区域/坐标/创建时间）
2. 直接修改右侧标题/内容/类型，点击「保存」即可更新记录

#### 3. 删除记录
1. 选中要删除的记录
2. 点击右侧「删除」按钮，确认后即可删除（不可逆）

### 四、记录筛选与搜索
1. **类型筛选**：左侧点击「全部」「坑点」「趣事」，快速过滤记录
2. **关键词搜索**：在左侧搜索框输入文字，实时匹配记录的**标题+内容**
3. **时间排序**：点击左侧「最新优先/最早优先」，切换记录排序方式
4. **分页查看**：左侧底部「上页/下页」翻找更多记录

### 五、导入导出（核心分享功能）
#### 1. 导出记录
- **导出单条**：选中要导出的记录，点击右侧「导出选中」，复制弹窗内的编码文本即可
- **导出整本日记**：点击插件底部「导出整本日记」，复制弹窗内的编码文本即可
- 导出的文本可直接发送给其他玩家，支持跨账号/跨服务器分享

#### 2. 导入记录
1. 复制其他玩家分享的**编码文本**
2. 点击插件底部「导入日记」
3. 将文本粘贴到弹窗输入框，点击「导入」即可
4. 若日记本名称重复，将**自动追加记录**并跳过重复内容；若为新名称，将创建新日记本

## ⌨️ 斜杠命令大全
在游戏聊天框输入即可使用：
```
/gd          # 打开/关闭插件主界面
/gd help     # 查看命令帮助
/gd new 名称 # 快速创建指定名称的日记本
/gd delete 名称 # 快速删除指定名称的日记本（需确认）
```

## 📌 注意事项
1. 插件仅适配**乌龟服1.18.1版本**，其他魔兽版本/私服暂不兼容
2. 记录的元数据（区域/坐标）为**创建记录时的实时信息**，编辑记录不会更新
3. 导入时请确保复制**完整的编码文本**，缺失部分会导致导入失败
4. 小地图按钮可在插件设置中隐藏（源码内`GameDiaryDB.settings.minimapShow`控制）
5. 单条记录内容最大支持2000字符，日记本名称最大30字符，标题最大100字符
6. 日记，最好就写几句最重要的话，太多了没有耐心，为了不要写这么多，我没有添加滚动条，你写太多，你自己也看不见,,,哈哈哈

## 🐛 常见问题
### Q1：游戏内看不到小地图按钮/插件界面？
A1：① 确认AddOns文件夹内为`GameDiary`根目录，无嵌套；② 角色选择界面勾选插件和「加载过期插件」；③ 输入`/gd`手动唤起界面。

### Q2：导入记录提示「校验失败」？
A2：原因是复制的导出文本**不完整/被修改**，让对方重新导出并完整复制（不要删减任何字符）。

### Q3：保存记录时提示「请选择记录类型/填写标题」？
A3：插件要求**记录类型（坑点/趣事）和标题为必填项**，补充后即可保存。

### Q4：删除日记本后，记录能否恢复？
A4：不能，删除操作**不可逆**，删除前请确认是否需要导出备份。

---
### 插件文件结构
```
GameDiary/
├─ media/
│   └─ ui/
│       ├─ bg-book-left.blp # 背景纹理,羊皮纸
│       └─ bg-book-right.blp
├─ GameDiary.lua       # 核心逻辑：CRUD/筛选/事件处理
├─ GameDiary.xml       # UI布局：主界面/导出/导入弹窗
├─ GameDiary_Config.lua # 配置常量：颜色/尺寸/音效/限制
├─ GameDiary_Minimap.lua # 小地图按钮功能
└─ GameDiary_Utils.lua  # 工具函数：Base64/序列化/时间格式化
```

**祝你玩的愉快！！！**
