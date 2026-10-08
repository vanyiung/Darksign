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


