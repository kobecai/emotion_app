# Emotion Release App

> A minimal emotional release tool designed for moments of intensity.
> No analysis. No judgment. Just release, acknowledge, and exit.

---

## 1. 产品定位（Updated）

**Emotion Release App** 是一款面向美国用户的、**单人使用、无社交、无评判**的情绪释放工具。

它不试图：

* 教育用户
* 分析情绪
* 让用户变得更好

它只做一件事：

> **在情绪最强烈的当下，给身体一个“释放 → 被承认 → 可以离开”的安全路径。**

关键词：

* Immediate
* Private
* Somatic (身体先于认知)
* Low commitment

---

## 2. 核心设计理念

### 2.1 情绪不是被“解决”的，而是被“放掉”的

* 情绪释放优先于理解
* 身体反馈优先于语言
* 结束感优先于引导

### 2.2 用户任何时刻都应该感觉“我可以走”

* 不强制输入
* 不强制反思
* 不强制留存

> App 的可信度来自 **不占用用户情绪**。

---

## 3. MVP 功能范围（基于当前实现）

### P0（已实现 / 核心）

1. **Hold-to-Release 交互**

   * 用户选择情绪（如 Anger / Sadness）
   * 长按触发释放
   * 持续时间代表情绪强度

2. **身体节奏驱动的释放体验**

   * Holding 阶段有呼吸节奏
   * Release 阶段有明确结束动画

3. **Done 页面（完成态）**

   * 明确确认“你已经释放了”
   * 提供立即退出的可能

---

### P1（已实现 / 稳定性增强）

4. **情绪回声（Bars）**

   * 在 Done 页展示
   * 表达“释放发生过”而非评分
   * 强度来自 holding 时长

5. **自适应 Done 启用时机**

   * Done 按钮不再固定 6 秒
   * 基于释放完成 + 最小安全时间

---

### P2（可选 / 延迟参与）

6. **Remember：给未来自己的句子**

   * 非强制
   * 非主流程
   * 通过轻 CTA 进入

---

## 4. 核心用户流程

### 4.1 主路径（90% 用户）

1. 打开 App
2. 选择情绪
3. Hold → Release
4. Done 页确认
5. 离开 App

> 不需要输入、不需要思考、不需要留下任何东西。

---

### 4.2 次路径（少数有余力的用户）

1. 完成释放
2. 在 Done 页看到轻 CTA
3. 自愿写一句给未来自己的话
4. 保存并返回 Done

---

## 5. 页面级设计说明

---

### 5.1 Holding / Releasing 页面

**目标**：

* 把注意力从“事情”拉回到“身体”

**关键特征**：

* 长按是唯一主要动作
* 视觉节奏与呼吸同步
* 没有数值、没有评价

**释放结束标志**：

* 明确的动画终止
* 不悬而未决

---

### 5.2 Done 页面（v3 稳定版）

**页面角色**：结束态（不是引导页）

#### 永远存在的 3 个元素

1. **完成确认文本**

   * “You let it out.”
   * “You held onto … for X seconds.”

2. **情绪回声 Bars**

   * 淡入
   * 一次轻微回落动画
   * 最终静止

3. **Done 按钮**

   * 较早出现
   * 出现即为可点击

---

#### 可选元素（晚出现）

4. **CTA：A note for your future self**

   * Text / ghost button
   * 无边框、无背景
   * 出现在页面稳定后

---

## 6. Remember 交互设计

### 6.1 CTA 设计

* 文案：A note for your future self
* 样式：

  * 次级文字色
  * 小一号字号
  * 不像按钮

### 6.2 触发后行为

* 打开轻量 Modal / Bottom Sheet
* 不离开 Done 页上下文

### 6.3 输入页内容

* 标题：For next time
* 单个文本输入
* 可直接关闭
* 保存后仅做极轻确认

---

## 7. 设计约束（必须遵守）

* ❌ 不在 Done 页强制输入
* ❌ 不在 Done 页做情绪分析
* ❌ 不出现“你应该…”
* ❌ 不在完成态引导下一个任务

---

## 8. 成功标准（非指标）

这个产品不是靠：

* 日活
* 时长
* 连续打卡

它的成功信号是：

> 用户在最糟糕的时刻，
> 愿意再次打开它。

---

## 9. 当前阶段的判断结论

* 产品已经具备 **清晰差异化**
* Done 页已进入「高级稳定态」
* 剩余优化应聚焦：

  * 节奏微调
  * 情绪强度映射
  * 下一次出现策略

> **现在不是加功能的时候，而是守住边界的时候。**

---

*This document reflects the current implemented scope and guiding principles. Future expansion should not violate the core promise: release, acknowledge, exit.*
