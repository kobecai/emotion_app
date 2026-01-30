很好，这一步我们就**完全落到工程层**。
下面是 **严格对应你 MVP 方案的 3 个页面 Flutter 组件层级结构**，不是示意图，而是**你可以直接照着写 Widget 的结构蓝图**。

我会给你：

1. **页面结构树（Widget Tree）**
2. **关键组件职责说明**
3. **几个实现时的“坑位提醒”**

不写完整代码，只给**最优结构**，避免你后期重构。

---

# 页面一：Home（情绪选择 + 长按释放前）

> 状态：**释放前（可能显示“过去的一句话”）**

---

## 🧱 Widget Tree（HomePage）

```
Scaffold
└── SafeArea
    └── Padding (16)
        └── Column
            ├── HeaderSection
            ├── SizedBox(height: 24)
            ├── EmotionGrid
            ├── SizedBox(height: 24)
            ├── OptionalPastNote
            ├── SizedBox(height: 16)
            ├── HoldToReleaseButton
            └── Spacer
```

---

## 🔹 HeaderSection

```
Column
├── Text("LETGO")
├── SizedBox(height: 8)
└── Text("How are you feeling?")
```

说明：

* `LETGO`：letterSpacing 拉开
* `How are you feeling?` 用中等字号即可

---

## 🔹 EmotionGrid

```
GridView.count (shrinkWrap: true)
├── EmotionButton(Angry)
├── EmotionButton(Sad)
├── EmotionButton(Anxious)
└── EmotionButton(Overwhelmed)
```

EmotionButton 内部建议结构：

```
GestureDetector
└── AnimatedContainer
    └── Center
        └── Text("Sad")
```

状态：

* selected → scale + color
* unselected → muted

---

## 🔹 OptionalPastNote（⚠️ 关键组件）

> **只在满足条件时 render，否则 SizedBox.shrink()**

```
AnimatedOpacity
└── Padding(horizontal: 12)
    └── Column
        ├── Text("From last time", style: caption)
        └── Text("“I’m doing my best.”", style: italic)
```

实现建议：

* opacity: 0 → 1
* duration: 300ms
* 字号小、颜色浅（Color.withOpacity(0.6)）

❌ 不可点击
❌ 不要 Card / Border

---

## 🔹 HoldToReleaseButton（核心）

```
GestureDetector
├── onLongPressStart
├── onLongPressEnd
└── AnimatedBuilder
    └── Container (circle)
        ├── CustomPaint (progress ring)
        └── Center
            └── Text("HOLD TO RELEASE")
```

状态变量：

* `isHolding`
* `holdDuration`

---

# 页面二：Done（释放完成确认页）

> 状态：**释放后，不出现过去那句话**

---

## 🧱 Widget Tree（DonePage）

```
Scaffold
└── SafeArea
    └── Padding (24)
        └── Column
            ├── Spacer
            ├── ConfirmationSection
            ├── SizedBox(height: 32)
            ├── FeedbackSection
            ├── Spacer
            └── DoneButton
```

---

## 🔹 ConfirmationSection

```
Column
├── Text("You let it out.", style: large)
├── SizedBox(height: 12)
└── Text("You held onto Sad for 2.7 seconds.")
```

可选加一句（更小）：

```
Text("Even a small release counts.")
```

---

## 🔹 FeedbackSection（How do you feel now?）

```
Column
├── Text("How do you feel now?")
├── SizedBox(height: 16)
└── Row
    ├── FeedbackButton("Lighter")
    ├── FeedbackButton("Same")
    └── FeedbackButton("Still heavy")
```

FeedbackButton 建议：

```
GestureDetector
└── AnimatedContainer
    └── Text(label)
```

* 点击后高亮
* 不强制选择（可直接 Done）

---

## 🔹 DoneButton

```
ElevatedButton
└── Text("Done")
```

行为：

* pop / navigate back to Home
* reset state

---

# 页面三：Mini History（极简历史页）

> 状态：**只展示，不分析**

---

## 🧱 Widget Tree（HistoryPage）

```
Scaffold
├── AppBar(title: Text("Your moments"))
└── ListView.builder
    ├── HistoryItem
    ├── HistoryItem
    └── ...
```

---

## 🔹 HistoryItem

```
Padding
└── Column (crossAxisAlignment: start)
    ├── Text("Sad · Jan 24")
    └── Text("2.7 seconds", style: caption)
```

⚠️ MVP 规则：

* 不可点击
* 不展开
* 不统计

---

## 空状态（第一次）

```
Center
└── Text(
   "Nothing here yet.\nCome back whenever you need to let something out.",
   textAlign: center
)
```

---

# 页面之间的状态流（非常重要）

```
HomePage
  ├── selectedEmotion
  ├── optionalPastNote
  └── holdDuration
        ↓
DonePage
  ├── emotion
  ├── duration
  └── feedback (optional)
        ↓
Persist locally
        ↓
Back to HomePage (clean state)
```

❌ 不跨页面共享 UI 状态
✅ 只传数据

---

## 三个工程级提醒（非常重要）

### ⚠️ 1. PastNote 一定是“弱存在”

* AnimatedOpacity
* 不占布局高度（opacity 0 但保留高度也行）
* 不要 ListTile / Card

---

### ⚠️ 2. Home 页永远保持“安静”

* 不 toast
* 不 snackbar
* 不 loading

---

### ⚠️ 3. 所有页面最大停留时间 < 60 秒

这是你产品的健康使用边界。

---

## 最后一句（给工程师的）

> **这是一个“状态驱动 UI”，不是“流程驱动 UI”。**

你现在这套结构：

* 不容易乱
* 非常好扩展
* 不会把自己写死

