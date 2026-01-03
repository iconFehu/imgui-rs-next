# imgui-rs 维护指南

## 当前状态分析

### 版本信息

- **Dear ImGui 版本**: v1.92.5 (在 `third_party/imgui` 中)
- **imgui-rs 当前绑定版本**: v1.92.5 (根据 README.md)
- **版本差距**: 1.92.5 已对齐

### 项目结构

```
imgui-rs-next/
├── third_party/
│   ├── imgui/              # Dear ImGui C++ 源码 (v1.92.5)
│   └── imgui-rs/            # Rust 绑定项目
│       ├── imgui-sys/       # 底层 FFI 绑定 (自动生成)
│       ├── imgui/           # 高级安全 API
│       └── xtask/           # 构建工具 (bindgen 等)
└── scripts/                 # 同步脚本
```

## 更新流程概述

imgui-rs 的更新流程依赖于以下工具链：

1. **Dear ImGui** (C++) → **cimgui** (C 包装器) → **bindgen** (Rust FFI) → **imgui-rs** (安全 Rust API)

### 关键依赖

- **cimgui**: 将 C++ ImGui API 转换为 C API 的工具
- **bindgen**: 从 C 头文件生成 Rust FFI 绑定
- **luajit**: cimgui 生成器需要

## 详细更新步骤

### 1. 更新 Dear ImGui 源码

当前项目中的 `third_party/imgui` 已经是 v1.92.5，但需要同步到 imgui-rs 的第三方目录：

```bash
# 更新 imgui-rs 中的 imgui 副本
cd third_party/imgui-rs/imgui-sys/third-party

# 编辑 update-imgui.sh，更新版本号
# 然后运行（需要提供本地 imgui 仓库路径）
./update-imgui.sh /path/to/imgui/repo
```

该脚本会更新以下目录：
- `imgui-master/imgui/`
- `imgui-docking/imgui/`
- `imgui-master-freetype/imgui/`
- `imgui-docking-freetype/imgui/`

### 2. 生成 cimgui C 绑定

需要先克隆 cimgui 项目：

```bash
git clone --recursive https://github.com/cimgui/cimgui.git /tmp/cimgui
cd /tmp/cimgui
# 确保使用与 imgui 版本对应的 cimgui 标签
```

然后为每个分支生成 C 绑定：

```bash
cd third_party/imgui-rs/imgui-sys/third-party/imgui-master
./update-cimgui-output.sh /tmp/cimgui/

cd ../imgui-docking
./update-cimgui-output.sh /tmp/cimgui/

# 同样处理 freetype 版本
cd ../imgui-master-freetype
./update-cimgui-output.sh /tmp/cimgui/

cd ../imgui-docking-freetype
./update-cimgui-output.sh /tmp/cimgui/
```

这会生成：
- `cimgui.h` 和 `cimgui.cpp`
- `definitions.json`
- `structs_and_enums.json`
- 其他元数据文件

### 3. 生成 Rust FFI 绑定

使用 xtask 工具生成 Rust 绑定：

```bash
cd third_party/imgui-rs
cargo xtask bindgen
```

这会生成：
- `imgui-sys/src/bindings.rs`
- `imgui-sys/src/wasm_bindings.rs`
- `imgui-sys/src/docking_bindings.rs`
- `imgui-sys/src/freetype_bindings.rs`
- 等等（根据特性组合）

**注意**: 需要安装 bindgen：
```bash
cargo install bindgen-cli
```

### 4. 修复编译错误

运行构建并修复由上游更改引起的错误：

```bash
cargo build
```

常见问题：
- **函数重命名**: 检查上游 ImGui 发布说明
- **函数移除**: 需要从 Rust API 中移除对应绑定
- **新函数重载**: bindgen 会生成 `igThingNil()` 和 `igThingFloat(...)` 等
- **内存布局变化**: 结构体字段顺序/类型变化可能导致段错误

### 5. 更新高级 Rust API

在 `imgui/src/` 中更新高级 API 以匹配新的底层绑定：

- 检查新函数并添加安全包装
- 更新已更改的 API
- 处理废弃的 API

### 6. 运行测试

```bash
# 运行所有测试
cargo test --workspace

# 测试不同特性组合
cargo test --features docking
cargo test --features freetype
cargo test --all-features

# 运行内存布局测试（重要！）
cargo test --release -- --ignored
```

### 7. 更新文档

- 更新 `README.md` 中的 Dear ImGui 版本徽章 URL
- 更新 `CHANGELOG.md`
- 检查 `docs/` 目录中的文档

### 8. 版本号管理

根据开发流程文档：
- 日常开发在 `main` 分支
- 发布时创建 `x.y-stable` 分支
- 只在发布到 crates.io 前更新 `Cargo.toml` 中的版本号

## 主要版本差异 (1.89.2 → 1.92.5)

根据 ImGui 的 CHANGELOG，主要变化包括：

### v1.90 (2024-01-17)
- 大量 API 改进和重构
- 新的输入系统
- 改进的表格 API

### v1.91 (2024-03-XX)
- 更多 API 稳定化
- 性能改进

### v1.92 (2024-XX-XX)
- 光标系统重构
- API 稳定化

**重要**: 查看 `third_party/imgui/docs/CHANGELOG.txt` 获取详细变更列表。

## 关键文件位置

### 绑定生成相关
- `imgui-sys/build.rs` - 构建脚本
- `imgui-sys/src/bindings.rs` - 自动生成的 FFI 绑定
- `xtask/src/bindgen.rs` - bindgen 工具代码

### 高级 API
- `imgui/src/` - 安全 Rust API 实现
- `imgui/src/ui.rs` - 主要的 UI API

### 更新脚本
- `imgui-sys/third-party/update-imgui.sh` - 更新 ImGui 源码
- `imgui-sys/third-party/*/update-cimgui-output.sh` - 生成 cimgui 绑定

## 常见问题排查

### bindgen 版本不匹配

检查 `imgui-sys/src/bindings.rs` 第一行记录的 bindgen 版本，确保使用相同版本：
```bash
bindgen --version
```

### 内存布局测试失败

如果内存布局测试失败，比较：
1. `imgui-sys/src/bindings.rs` 中的结构体定义
2. `imgui/src/` 中对应的 Rust 结构体

确保字段顺序和类型完全匹配。

### cimgui 生成失败

- 确保 luajit 已安装
- 检查 cimgui 版本是否与 imgui 版本兼容
- 查看 cimgui 的发布说明

## 下一步行动

1. ✅ 分析当前状态（已完成）
2. ⏳ 更新 imgui-rs 中的 ImGui 源码副本
3. ⏳ 生成新的 cimgui 绑定
4. ⏳ 运行 bindgen 生成 Rust 绑定
5. ⏳ 修复编译错误和 API 变化
6. ⏳ 更新测试和文档
7. ⏳ 准备发布

## 参考资源

- [Dear ImGui 仓库](https://github.com/ocornut/imgui)
- [cimgui 仓库](https://github.com/cimgui/cimgui)
- [imgui-rs 仓库](https://github.com/imgui-rs/imgui-rs)
- [升级文档](third_party/imgui-rs/docs/upgrading-imgui.md)
- [开发流程](third_party/imgui-rs/docs/development-process.md)
