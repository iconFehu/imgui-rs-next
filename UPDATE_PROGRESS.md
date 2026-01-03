# imgui-rs 更新进度

## 步骤 1: 更新 ImGui 源码 ✅

- [x] 检查当前版本
  - imgui-rs 中: v1.92.5
  - 目标版本: v1.92.5
- [x] 更新 imgui-master/imgui → v1.92.5
- [x] 更新 imgui-master-freetype/imgui → v1.92.5
- [x] 更新 imgui-docking/imgui → v1.92.5 (需要检查)
- [x] 更新 imgui-docking-freetype/imgui → v1.92.5 (需要检查)

## 步骤 2: 生成 cimgui C 绑定 ⏳

需要准备：
- [x] 克隆 cimgui 仓库
- [x] 检查 luajit 是否安装
- [x] 为每个变体生成 cimgui 绑定

## 步骤 3: 生成 Rust FFI 绑定 ⏳

- [x] 安装 bindgen (如果需要)
- [x] 运行 `cargo xtask bindgen`
- [x] 检查生成的绑定文件

## 步骤 4: 修复编译错误 ⏳

- [x] 运行 `cargo build`
- [x] 修复 API 变更
- [x] 更新高级 Rust API

## 步骤 5: 运行测试 ⏳

- [ ] 运行所有测试
- [x] 运行内存布局测试
- [x] 运行 `cargo test -p imgui --lib`
- [x] 运行 `cargo test --features docking`
- [ ] 运行 `cargo test --all-features`（external 需要外部 cimgui）
- [ ] 运行 `cargo test --features "docking freetype tables-api imgui-sys/use-vcpkg"`（需要 vcpkg 安装 freetype:x64-windows-static-md）

## 步骤 6: 更新文档 ⏳

- [x] 更新 README.md
- [x] 更新 CHANGELOG.md
- [x] 更新版本信息
