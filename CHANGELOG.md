# Changelog
All notable changes to this project will be documented in this file. See [conventional commits](https://www.conventionalcommits.org/) for commit guidelines.

- - -
## v0.30.0 - 2026-10-15
#### Features
- 播放器控件改为独立圆角方框 - (0445eec) - HttpAnimations
- 重新设计播放器屏幕控制 - (4a2683e) - HttpAnimations
#### Bug Fixes
- 缩小视频卡片菜单按钮，修复继续观看溢出 - (b5a212a) - HttpAnimations
- 改用直播趋势标签页替代已下线的热门页 - (5994212) - HttpAnimations
- 会员专享视频直接退出并弹出错误提示 - (1ae27e7) - HttpAnimations

- - -

## v0.29.0 - 2026-10-15
#### Features
- 隐藏频道会员专享视频 - (79d1c07) - HttpAnimations

- - -

## v0.28.1 - 2026-10-15
#### Bug Fixes
- 更多菜单抽屉从右侧打开 - (27f4636) - HttpAnimations

- - -

## v0.28.0 - 2026-10-15
#### Features
- (**api**) Invidious 备用后端 - (aef2dbc) - HttpAnimations
- (**api**) 视频详情缓存 - (505d66b) - HttpAnimations
- (**channel**) 频道页标签页 - (54e9ac2) - HttpAnimations
- (**feed**) 信息流密度 - (43f4b53) - HttpAnimations
- (**feed**) 隐藏频道与视频 - (816ed1f) - HttpAnimations
- (**history**) 管理筛选删除 - (83742b7) - HttpAnimations
- (**player**) 迷你播放器显示视频 - (f4a4f29) - HttpAnimations
- (**player**) 迷你播放器导航与关闭 - (efa0805) - HttpAnimations
- (**player**) 下拉收缩动画 - (65a709b) - HttpAnimations
- (**player**) 更多快捷键 - (2b56e8e) - HttpAnimations
- (**player**) 可播放性错误处理 - (ec5982b) - HttpAnimations
- (**player**) 编解码器偏好 - (e50b8f6) - HttpAnimations
- (**playlist**) 翻页加载 - (8b85c51) - HttpAnimations
- (**settings**) 省流模式 - (b6b6f07) - HttpAnimations
- (**settings**) 强调色 - (e29c77f) - HttpAnimations
- (**settings**) 网络代理 - (a930441) - HttpAnimations
- (**settings**) 备份与恢复 - (76c8e62) - HttpAnimations
- (**sponsorblock**) 补齐分类 - (b708ed6) - HttpAnimations
- (**subscriptions**) 并行加载订阅流 - (786dd1b) - HttpAnimations
- (**subscriptions**) 频道上传提醒开关 - (3bf77f1) - HttpAnimations
- (**subscriptions**) 订阅分组 - (350bc3c) - HttpAnimations
- (**subscriptions**) takeout csv 导入 - (c0420b8) - HttpAnimations
- (**ui**) 无障碍语义标注 - (5fd5379) - HttpAnimations
- (**ui**) 长按视频卡片菜单 - (34ef35c) - HttpAnimations
- (**watch**) 免打扰开关 - (9b4eebe) - HttpAnimations
- (**watchlater**) 排序与进度 - (2966c03) - HttpAnimations
- (**web**) Docker 镜像 - (b254046) - HttpAnimations
#### Bug Fixes
- (**docs**) flatpak 无 GPG 签名 - (f6d07a4) - HttpAnimations
- (**ios**) 移除 Swift 并发注解，改用同步 API 编译 PiP 控制器 - (831eb8a) - HttpAnimations
- (**ios**) 显式标注 PiP 方法的主线程隔离 - (98cc43d) - HttpAnimations
- (**ios**) 将 PiP 方法改为异步以消除 Swift 并发警告 - (33e0395) - HttpAnimations
- (**ios**) 修复 PiP 控制器的 Swift 并发隔离错误 - (b31da38) - HttpAnimations
- (**ios**) 画中画三重故障 - (e34470e) - HttpAnimations
- (**player**) 小屏进度条触控 - (35e4192) - HttpAnimations
- (**settings**) 嵌套 SponsorBlock 选项 - (df65463) - HttpAnimations
- (**shell**) 移动端导航栏精简 - (87215a8) - HttpAnimations
- (**shell**) 画中画隐藏导航栏 - (56a404b) - HttpAnimations
- (**theme**) OLED 黑色界面元素 - (7456438) - HttpAnimations

- - -

## v0.27.0 - 2026-10-14
#### Features
- (**comments**) 回复、排序与徽章 - (d03c269) - HttpAnimations
- (**downloads**) 离线下载 - (5d6571d) - HttpAnimations
- (**feeds**) 下拉刷新 - (ce39603) - HttpAnimations
- (**feeds**) 隐藏已看视频 - (ed75df2) - HttpAnimations
- (**feeds**) 隐藏 Shorts - (7f73592) - HttpAnimations
- (**links**) 深度链接 - (47fbcc6) - HttpAnimations
- (**player**) 播放队列 - (575b06d) - HttpAnimations
- (**player**) 自动播放倒计时 - (51b7633) - HttpAnimations
- (**player**) 统计信息叠加层 - (c5de4ff) - HttpAnimations
- (**player**) 全屏横屏旋转 - (dc169a0) - HttpAnimations
- (**player**) 直播与首映支持 - (f026641) - HttpAnimations
- (**player**) 画面缩放模式 - (b86584b) - HttpAnimations
- (**playlists**) 排序重命名导出 - (1d4799b) - HttpAnimations
- (**search**) 粘贴链接直达 - (b8d1bd7) - HttpAnimations
- (**search**) 搜索筛选器 - (5e33ac8) - HttpAnimations
- (**search**) 搜索建议 - (02921af) - HttpAnimations
- (**ui**) 热门页 - (3fca4ae) - HttpAnimations
- (**ui**) 分享与复制链接 - (14394a0) - HttpAnimations
- (**ui**) 分享与复制链接 - (bdb3f44) - HttpAnimations
- (**watch**) 续播与继续观看 - (ad427d3) - HttpAnimations
- (**watch**) 章节列表 - (3fa4d42) - HttpAnimations
- (**watch**) 描述链接与时间戳跳转 - (916d383) - HttpAnimations
- (**watch**) 点踩数显示 - (05b120f) - HttpAnimations
- (**watch**) 章节列表 - (4b1c6ae) - HttpAnimations
#### Bug Fixes
- 修复合并后的 shell 索引与 feed 过滤 - (33bd792) - HttpAnimations

- - -

## v0.26.0 - 2026-10-14
#### Features
- (**player**) 进度条最热门区段热图 - (d3370d5) - HttpAnimations

- - -

## v0.25.0 - 2026-10-14
#### Features
- (**player**) 进度条缓冲区间与缩略图预览 - (d9fc8d8) - HttpAnimations

- - -

## v0.24.0 - 2026-10-14
#### Features
- (**player**) 默认播放速度 - (bc7ec8e) - HttpAnimations
- (**player**) 默认画质偏好 - (94132b8) - HttpAnimations

- - -

## v0.23.0 - 2026-10-14
#### Features
- (**player**) 仅音频播放模式 - (5fe1054) - HttpAnimations

- - -

## v0.22.0 - 2026-10-14
#### Features
- (**player**) 循环与随机播放模式 - (0b95e7f) - HttpAnimations

- - -

## v0.21.0 - 2026-10-14
#### Features
- (**player**) 屏幕音量与静音控制 - (d76bee7) - HttpAnimations

- - -

## v0.20.0 - 2026-10-14
#### Features
- (**player**) 触摸手势控制 - (ed7ca91) - HttpAnimations

- - -

## v0.19.0 - 2026-10-14
#### Features
- (**player**) 字幕与隐藏式字幕支持 - (0a50c96) - HttpAnimations
- (**player**) iOS 画中画支持 - (081da2c) - HttpAnimations
#### Bug Fixes
- 修正 PiP 轨道 ID 常量 - (d5ab772) - HttpAnimations
- 修复 iOS 构建与代码格式 - (3d06847) - HttpAnimations

- - -

## v0.18.0 - 2026-10-13
#### Features
- (**home**) 基于观看历史个性化首页推荐 - (2df8711) - HttpAnimations
- (**player**) 离开播放页时以迷你播放器继续播放 - (766a1ca) - HttpAnimations
- (**player**) 视频结束后显示重播和下一个视频的结束画面 - (0f77547) - HttpAnimations

- - -

## v0.17.2 - 2026-10-13
#### Bug Fixes
- (**player**) 画中画只渲染视频画面 - (2b2a269) - HttpAnimations
- (**player**) 应用退到后台时继续播放音频 - (d702651) - HttpAnimations
- (**player**) 触摸点击切换控制层而非暂停播放 - (fb76573) - HttpAnimations

- - -

## v0.17.1 - 2026-10-13
#### Bug Fixes
- 分离音轨按视频容器配对 - (f01cbf4) - HttpAnimations

- - -

## v0.17.0 - 2026-10-13
#### Features
- (**ui**) 视频卡片与列表的更多操作菜单 - (9103b16) - HttpAnimations

- - -

## v0.16.0 - 2026-10-13
#### Features
- (**player**) 播放时自动隐藏播放控制栏 - (ee6d24d) - HttpAnimations
- (**ui**) 已观看视频标记 - (8e1595f) - HttpAnimations
- 本地播放列表 - (4c3d6f7) - HttpAnimations

- - -

## v0.15.1 - 2026-10-13
#### Bug Fixes
- (**player**) 播放器随页面内容一起滚动 - (63e42e3) - HttpAnimations

- - -

## v0.15.0 - 2026-10-13
#### Features
- (**player**) 将视频设置合并到设置菜单 - (9229c41) - HttpAnimations

- - -

## v0.14.1 - 2026-10-13
#### Bug Fixes
- 审查修复搜索播放列表与播放细节 - (e78789c) - HttpAnimations

- - -

## v0.14.0 - 2026-10-13
#### Features
- 移动端后台音频播放 - (ce7fe9e) - HttpAnimations
#### Bug Fixes
- 加固后台音频会话生命周期 - (92e2976) - HttpAnimations
- 加固画中画实现 - (a69b9b5) - HttpAnimations
- 加固上传通知与权限配置 - (2e3bbdd) - HttpAnimations
- 修复 Linux 与 Android 构建依赖 - (c4fe53b) - HttpAnimations

- - -

## v0.13.0 - 2026-10-13
#### Features
- 画中画播放 - (48c2bea) - HttpAnimations
- 频道上传通知 - (108ebc9) - HttpAnimations
#### Bug Fixes
- 加固画中画实现 - (0bce7d9) - HttpAnimations
- 加固上传通知与权限配置 - (d1a2842) - HttpAnimations
- 加固上传通知与权限配置 - (d43f5c7) - HttpAnimations
- 修复 Linux 与 Android 构建依赖 - (1acffc5) - HttpAnimations
- 修复 Linux 与 Android 构建依赖 - (4c4326f) - HttpAnimations

- - -

## v0.12.0 - 2026-10-13
#### Features
- 播放列表与稍后观看 - (4bc6231) - HttpAnimations
- OPML 订阅导入导出 - (c78b472) - HttpAnimations

- - -

## v0.11.0 - 2026-10-13
#### Features
- 视频页评论 - (f5b0c83) - HttpAnimations
- DeArrow 众包标题与缩略图 - (48955ea) - HttpAnimations
- SponsorBlock 跳过赞助片段 - (7f38a90) - HttpAnimations

- - -

## v0.10.0 - 2026-10-13
#### Features
- 进度条章节标记 - (85df0f1) - HttpAnimations
- 播放页睡眠定时器 - (ff658ae) - HttpAnimations

- - -

## v0.9.0 - 2026-10-13
#### Features
- 播放器键盘快捷键 - (e2b5ada) - HttpAnimations

- - -

## v0.8.0 - 2026-10-13
#### Features
- 播放速度调节 - (dbf0120) - HttpAnimations

- - -

## v0.7.0 - 2026-10-13
#### Features
- 空格键切换播放暂停 - (a96f0d7) - HttpAnimations
- 画质与音轨拆分为两个下拉菜单 - (c6ec0cf) - HttpAnimations
- 左右方向键快进快退五秒 - (909c1ce) - HttpAnimations
- 点击视频画面切换播放暂停 - (0461f19) - HttpAnimations
- 侧边栏可折叠为小图标栏 - (a60f292) - HttpAnimations
- 设置项固定在侧边栏底部 - (a9e5f44) - HttpAnimations
- 播放页作者旁显示频道头像 - (3b9118b) - HttpAnimations
- 相关视频显示缩略图并抽取列表项组件 - (35d076a) - HttpAnimations
- 导出标准 mcpb 扩展包 - (9d76440) - HttpAnimations
#### Bug Fixes
- 切换流时跳过期 seek 并处理切换失败 - (a92c11a) - HttpAnimations
- VISIONOS 回退流全部探测失败时不再丢弃 - (97b6400) - HttpAnimations
- 切换视频流时保留播放进度与暂停状态 - (6db7bb9) - HttpAnimations
- 桌面端分离音轨未附加导致视频无声 - (c6ac24f) - HttpAnimations
- 探测全部失败时仍重试并避免双代理前缀 - (8eecb03) - HttpAnimations
- 部分视频自适应清晰度因 poToken 校验只剩 360p - (edd4bb5) - HttpAnimations
- 搜索结果视频缩略图无法显示 - (0d79afe) - HttpAnimations
- 探测并过滤不可播放的流 - (3d0912b) - HttpAnimations

- - -

## v0.6.0 - 2026-10-13
#### Features
- 导出时使用系统保存对话框 - (48763ab) - HttpAnimations
- 设置中导出 mcsp 文件 - (9fe88ed) - HttpAnimations
- 新增 mcsp 导出文件 - (743d32a) - HttpAnimations
- 桌面端新增 MCP 服务器 - (fa02dd8) - HttpAnimations

- - -

## v0.5.0 - 2026-10-12
#### Features
- 播放页改为内嵌页面 - (62b1c5c) - HttpAnimations
- 允许在设置中关闭搜索历史 - (3205cf7) - HttpAnimations
- 清除历史记录前添加确认对话框 - (d4df622) - HttpAnimations
- 清除历史按钮移至设置页 - (38ae6c2) - HttpAnimations
- 搜索页显示搜索历史 - (1243043) - HttpAnimations
- 搜索改为独立标签页 - (d6a09d3) - HttpAnimations
- 关于页使用真实应用图标 - (53744f5) - calico
#### Bug Fixes
- OLED 主题下顶栏使用纯黑背景 - (6018928) - HttpAnimations
- OLED 主题下导航栏与侧边栏使用纯黑背景 - (729f7f0) - HttpAnimations
- 修复视频卡片两行标题时底部溢出 - (78fc9b2) - HttpAnimations
- 修复订阅和频道页视频缺少播放量和上传时间 - (fef4399) - HttpAnimations

- - -

## v0.4.0 - 2026-10-12
#### Features
- 窗口控制按钮移入侧边栏 - (645f748) - calico
- 重做桌面端侧边导航栏 - (70c727e) - calico

- - -

## v0.3.1 - 2026-10-12
#### Bug Fixes
- 对齐设置页语言下拉菜单 - (3c12d7e) - calico

- - -

## v0.3.0 - 2026-10-12
#### Features
- 网页版播放器与内置数据接口 - (e86656c) - calico
#### Bug Fixes
- 覆盖 CI 覆盖率诊断与标记 - (e38f714) - calico

- - -

## v0.2.0 - 2026-10-12
#### Features
- 网页版 CORS 提示与代理设置 - (fff9887) - calico

- - -

## v0.1.0 - 2026-10-12
#### Features
- NewTube 客户端、落地页与发布流水线 - (a2f41d4) - calico

- - -

Changelog generated by [cocogitto](https://github.com/cocogitto/cocogitto).