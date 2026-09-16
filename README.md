# DARK RING / 暗环

原创黑暗奇幻 WebGL 交互作品。所有火焰、噪声、圆环及余烬均由程序生成，无游戏贴图、音效、模型或其他游戏素材。

## 本地运行

安装 Node.js 22.12+（建议使用 Node.js LTS，包含 npm）。在终端中执行：

```powershell
cd "D:\2\dark ring"
npm install
npm run dev
```

打开终端显示的本地网址（默认 http://localhost:5173）。退出时按 Ctrl+C。不要直接双击 index.html，GLSL 模块需要 Vite 处理。

本机还配备了独立的 `.tools` Node.js 环境：可以直接双击 `start-dev.cmd` 启动，不改动系统设置。若当前终端找不到 npm，可先执行以下命令再运行上述 npm 命令：

```powershell
$nodeDir = Get-ChildItem .tools -Directory -Filter 'node-*-win-x64' | Select-Object -First 1
$env:Path = $nodeDir.FullName + ';' + $env:Path
```

`.tools` 仅用于本机，不提交到 GitHub；其他电脑安装标准 Node.js 后即可运行。

若 PowerShell 阻止 npm.ps1，改用 `npm.cmd install`、`npm.cmd run dev`。首次安装需要联网。

在 IntelliJ IDEA 中选择 **File → Open → D:\2\dark ring**，设置 Node.js 解释器后，可以从底部 Terminal 执行上述命令，或在 package.json 的 scripts 旁运行 dev / build。无需 Java、Maven 或 Gradle。

```powershell
npm run build
npm run preview
```

构建结果在 dist/，预览默认 http://localhost:4173。dev 配置监听局域网地址，可用手机访问同网络下的电脑 IP:5173（需本机防火墙允许）。

## 交互

- 鼠标靠近火环：局部扰动增强；触屏拖动也可扰动。
- 点击画面（键盘 Tab 可聚焦转场按钮）：圆环收缩、黑暗从中心扩张吞噬光晕，随后重燃。支持重复触发，过渡中避免叠加。
- QQ 内置浏览器若黑屏或卡顿，请在系统浏览器打开，并确认硬件加速可用。

## 项目结构

```text
index.html                         页面与交互控件
src/main.js                        场景、HDR 后处理、交互与动画状态
src/style.css                      响应式布局
src/shaders/fullscreen.vert.glsl    全屏顶点着色器
src/shaders/ring.frag.glsl          极坐标三维噪声 / 五层 FBM 火焰
src/shaders/embers.*.glsl           GPU 余烬生命周期
src/shaders/consume.frag.glsl       Bloom 后的吞噬遮罩
vite.config.js                     相对静态资源路径
.github/workflows/deploy.yml        GitHub Pages 自动部署
```

半浮点渲染目标保留 HDR 亮度，后处理顺序为 RenderPass → UnrealBloomPass → 吞噬遮罩 → OutputPass。黑色圆心由 Shader 裁切得到。角度先映射到单位圆，再输入噪声，避免极坐标接缝。可在 main.js 中调整 Bloom 强度，或在 ring.frag.glsl 中调整半径、火焰厚度及色彩。所有 .glsl 通过 Vite `?raw` 导入。

## Vercel 部署

1. 将**本文件夹里的项目**推送到自己的 GitHub 仓库，提交 package-lock.json，不提交 node_modules、dist 或 .tools。
2. 在 Vercel 选择 Add New → Project，导入仓库。
3. Framework Preset 选择 Vite。若仓库根目录就是本项目，Root Directory 保持默认；若在子目录则选对应子目录。
4. Build Command：`npm run build`；Output Directory：`dist`；Node.js 选择 22 或兼容的更新版本。
5. 点击 Deploy，完成后分享生成的 HTTPS 网址。后续推送由 Vercel 自动重新部署。

这是纯静态单页，无后台、账号或环境变量，不需要 SPA rewrite。

## GitHub Pages 部署

1. 将本项目作为仓库根目录推送到 GitHub 的 main 分支，包含 package-lock.json 和 .github/workflows/deploy.yml。
2. 在仓库 Settings → Pages → Build and deployment 中，将 Source 设为 GitHub Actions。
3. 推送 main 或在 Actions 中手动运行 Deploy to GitHub Pages。
4. 等待工作流成功，然后打开 Pages 提供的网址。

vite.config.js 已使用 `base: './'`，兼容 `https://用户名.github.io/仓库名/` 子路径以及 Vercel 域名根路径。分支不是 main 时，请修改工作流 branches。私有仓库的 Pages 可用性取决于 GitHub 套餐。

参考：[Vite 部署文档](https://vite.dev/guide/static-deploy)、[Vercel 的 Vite 文档](https://vercel.com/docs/frameworks/frontend/vite)。

画面采用无标题的纯黑全屏布局，圆周火光带有不均匀暗红火舌，六点钟方向的光柱延伸到画面下缘。所有效果仍由原创 GLSL 程序生成。

圆周采用横向杏仁形的柔和体积泛光，低频 FBM 使光雾缓慢变化。没有向内吸入的火舌或旋涡；少量余烬在圆外漂浮。保留左下缘高光和底部光柱。


当前画面固定使用最高预设（完整 240 粒子，最高 2 倍设备像素比），已移除画质和暂停按钮。系统开启减少动态效果时仅降低动画速度。球体具有微弱反射光，粒子沿三维轨道绕行并按球面遮挡。

