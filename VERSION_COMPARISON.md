# ImGui 版本对比分析 (1.89.2 → 1.92.5)

## 概述

本文档总结了从 Dear ImGui v1.89.2 到 v1.92.5 的主要变化，这些变化需要在更新 imgui-rs 时特别注意。

## 主要版本里程碑

- **v1.89.2** (2023-04-05) - imgui-rs 当前绑定版本
- **v1.90.0** (2023-11-15) - 重大更新
- **v1.91.0** (2024-07-30) - 重要改进
- **v1.92.0** (2025-06-25) - 最新稳定版本
- **v1.92.5** (2025-11-20) - 当前目标版本

## 重大破坏性变更 (Breaking Changes)

### 1. 键修饰符重命名 (v1.89.0, v1.92.5 中移除)

```cpp
// 旧 API (已废弃)
ImGuiKey_ModCtrl  → ImGuiMod_Ctrl
ImGuiKey_ModShift → ImGuiMod_Shift
ImGuiKey_ModAlt   → ImGuiMod_Alt
ImGuiKey_ModSuper → ImGuiMod_Super
```

**影响**: imgui-rs 的 `Key` 枚举和相关 API 需要更新。

### 2. BeginChild API 重构 (v1.90.0, v1.90.9, v1.91.1)

```cpp
// 旧 API
BeginChild(name, size, 0, ImGuiWindowFlags_NavFlattened)
BeginChild(name, size, 0, ImGuiWindowFlags_AlwaysUseWindowPadding)

// 新 API
BeginChild(name, size, ImGuiChildFlags_NavFlattened, 0)
BeginChild(name, size, ImGuiChildFlags_AlwaysUseWindowPadding, 0)
```

**标志重命名**:
- `ImGuiChildFlags_Border` → `ImGuiChildFlags_Borders`
- `ImGuiWindowFlags_NavFlattened` → `ImGuiChildFlags_NavFlattened` (移动到 ImGuiChildFlags)
- `ImGuiWindowFlags_AlwaysUseWindowPadding` → `ImGuiChildFlags_AlwaysUseWindowPadding` (移动到 ImGuiChildFlags)

**影响**: `imgui/src/child_window.rs` 和相关 API 需要更新。

### 3. SetItemAllowOverlap 废弃 (v1.89.7, v1.92.5 中移除)

```cpp
// 旧 API (已废弃，从未正确工作)
SetItemAllowOverlap()

// 新 API
SetNextItemAllowOverlap()  // 必须在 item 之前调用
```

**影响**: `Ui::set_item_allow_overlap` 需要改为 `Ui::set_next_item_allow_overlap`。

### 4. TreeNode/Selectable 标志重命名 (v1.89.7, v1.89.9, v1.92.4 中移除)

```cpp
ImGuiTreeNodeFlags_AllowItemOverlap   → ImGuiTreeNodeFlags_AllowOverlap
ImGuiSelectableFlags_AllowItemOverlap  → ImGuiSelectableFlags_AllowOverlap
```

**影响**: 相关枚举和 API 需要更新。

### 5. Clipper API 变更 (v1.89.9, v1.92.4 中移除)

```cpp
// 旧 API
ImGuiListClipper::IncludeRangeByIndices() 

// 新 API
ImGuiListClipper::IncludeItemsByIndex()
```

**影响**: `imgui/src/clipper.rs` 需要更新。

### 6. IO API 变更 (v1.89.8, v1.92.5 中移除)

```cpp
// 旧 API (已废弃)
io.ClearInputCharacters()

// 新 API
io.ClearInputKeys()  // 已足够
```

**影响**: `Io` 结构体的方法需要更新。

### 7. Vulkan 后端变更 (v1.92.4)

```cpp
// ImGui_ImplVulkan_InitInfo 结构体字段移动
init_info.RenderPass   → init_info.PipelineInfoMain.RenderPass
init_info.Subpass      → init_info.PipelineInfoMain.Subpass
init_info.MSAASamples  → init_info.PipelineInfoMain.MSAASamples
```

**影响**: 如果 imgui-rs 有 Vulkan 相关代码，需要更新。

## 重要新功能

### 1. 拖放系统增强 (v1.92.5)

- 新增 `ImGuiDragDropFlags_AcceptDrawAsHovered` 标志
- 新增拖放目标样式配置：
  - `ImGuiCol_DragDropTargetBg`
  - `style.DragDropTargetRounding`
  - `style.DragDropTargetBorderSize`
  - `style.DragDropTargetPadding`

### 2. 多选功能 (v1.92.5)

- 新增 `ImGuiMultiSelectFlags_NoSelectOnRightClick` 标志

### 3. 表格改进 (v1.92.5)

- 修复嵌套表格的 bug
- 改进角度表头的自动调整大小

### 4. 输入文本改进 (v1.92.5)

- 改进粘贴处理（UTF-8 边界截断）
- 修复只读模式下的断言问题
- 修复多行文本换行的崩溃问题

### 5. 导航系统改进 (v1.92.5)

- 重新设计 PageUp/PageDown 逻辑
- 改进从不可见项目导航的行为

### 6. 新后端 (v1.92.5)

- 新增 `imgui_impl_null` 后端（用于无输入/无输出的上下文）

## 需要重点检查的 imgui-rs 文件

### 核心 API 文件

1. **`imgui/src/key.rs`**
   - 更新键修饰符枚举
   - 检查 `Key::ModCtrl` 等是否已更新

2. **`imgui/src/child_window.rs`**
   - 更新 `ChildFlags` 枚举
   - 更新 `BeginChild` API 签名
   - 检查 `WindowFlags` 中已移动的标志

3. **`imgui/src/ui.rs`**
   - 更新 `set_item_allow_overlap` → `set_next_item_allow_overlap`
   - 检查所有使用旧 API 的地方

4. **`imgui/src/io.rs`**
   - 移除或废弃 `clear_input_characters`
   - 确保 `clear_input_keys` 可用

5. **`imgui/src/clipper.rs`**
   - 更新 `IncludeRangeByIndices` → `IncludeItemsByIndex`

6. **`imgui/src/tree_node.rs`** 和 **`imgui/src/selectable.rs`**
   - 更新标志枚举名称

### 样式相关

7. **`imgui/src/style.rs`**
   - 添加新的拖放目标样式字段
   - 检查颜色枚举

### 枚举和标志

8. **`imgui/src/enums.rs`** 或相关文件
   - 更新所有重命名的枚举
   - 检查废弃的枚举值

## 测试重点

### 内存布局测试

确保运行以下测试（这些测试会检查结构体内存布局）：

```bash
cargo test --release -- --ignored
```

### 功能测试

重点测试以下功能：
- 子窗口和 ChildFlags
- 键修饰符处理
- 拖放功能
- 表格嵌套
- 输入文本（特别是多行和只读模式）
- 导航系统

## 更新检查清单

- [ ] 更新 `imgui-sys` 中的 ImGui 源码
- [ ] 生成新的 cimgui 绑定
- [ ] 运行 `cargo xtask bindgen` 生成 Rust 绑定
- [ ] 修复编译错误
- [ ] 更新键修饰符 API
- [ ] 更新 BeginChild API
- [ ] 更新 SetItemAllowOverlap → SetNextItemAllowOverlap
- [ ] 更新 TreeNode/Selectable 标志
- [ ] 更新 Clipper API
- [ ] 更新 IO API
- [ ] 添加新的拖放样式支持
- [ ] 运行所有测试
- [ ] 运行内存布局测试
- [ ] 更新 CHANGELOG.md
- [ ] 更新 README.md 中的版本徽章
- [ ] 检查示例代码是否需要更新

## 参考资源

- [Dear ImGui v1.92.5 发布说明](https://github.com/ocornut/imgui/releases/tag/v1.92.5)
- [Dear ImGui CHANGELOG](third_party/imgui/docs/CHANGELOG.txt)
- [imgui-rs 升级文档](third_party/imgui-rs/docs/upgrading-imgui.md)

## 注意事项

1. **bindgen 版本**: 当前使用 bindgen 0.63.0，确保使用相同版本生成新绑定
2. **cimgui 版本**: 确保使用与 ImGui v1.92.5 兼容的 cimgui 版本
3. **向后兼容**: 考虑是否需要为废弃的 API 添加 `#[deprecated]` 属性
4. **测试覆盖**: 确保新功能和修复都有相应的测试
