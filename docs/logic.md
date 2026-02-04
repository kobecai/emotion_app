# Hold 圆圈转动与回收逻辑（可调参说明）

本文档描述 Home 页面中按住圆圈的转动与松手后的“收回”动画逻辑，便于理解与调参。

对应实现文件：
- lib/ui/features/home/widgets/hold_release_button.dart

---

## 1) 圆圈显示结构（渲染层）

圆圈的可见部分由 `_ProgressRingPainter` 绘制，核心参数来自 `_RingVisual`：

- `rotation`: 起始角度（弧线整体旋转）
- `radius`: 半径
- `strokeWidth`: 线宽
- `opacity`: 透明度
- `sweep`: 弧度（弧线长度）

绘制函数：

```
canvas.drawArc(
  Rect.fromCircle(center, radius),
  -pi/2 + rotation,
  sweep,
  false,
  ringPaint,
)
```

起始角度固定从 12 点方向（`-pi/2`），然后叠加 `rotation`。

---

## 2) 按住时的转动逻辑（Hold 状态）

### 2.1 计时驱动（Ticker + Stopwatch）

- 按下触发 `_onPressStart()`。
- 启动 `_holdStopwatch`（用于累计按住时间）。
- 启动 `_holdTicker`，每帧计算本帧时间差 `dtSeconds`，并更新 `rotation`：

```
_rotationAngle += _rotationSpeedForSeconds(tSeconds) * dtSeconds
```

其中 `tSeconds` 为按住的累计秒数。

### 2.2 转速曲线（循环分段）

转速由 `_rotationSpeedForSeconds(t)` 决定。它按 **6 秒为一个循环** (`_rotationCycleSeconds = 6.0`)，在循环内分 4 个阶段：

| 阶段 | 时长 | 速度变化 | 曲线 | 参数 |
|---|---:|---|---|---|
| Stage 1 | 0.6s | 从慢 → 快 | easeOut | 80 → 160 deg/s |
| Stage 2 | 1.8s | 从快 → 慢 | easeInOut | 160 → 70 deg/s |
| Stage 3 | 1.2s | 从慢 → 中快 | easeInOut | 70 → 140 deg/s |
| Stage 4 | 2.4s | 从中快 → 慢 | easeInOut | 140 → 60 deg/s |

参数来源：

- `_rotationStartDegPerSec = 80.0`
- `_rotationPeakDegPerSec = 160.0`
- `_rotationMidLowDegPerSec = 70.0`
- `_rotationMidHighDegPerSec = 140.0`
- `_rotationEndDegPerSec = 60.0`

最终转为弧度/秒：

```
return speedDeg * pi / 180.0
```

> 调参建议：
> - 想更“急促”：增大 Peak 与 MidHigh。
> - 想更“悠缓”：降低 Peak，并拉长 Stage2/Stage4。
> - 想改变节奏：调整 `_rotationCycleSeconds` 和各 Stage 时长占比。

### 2.3 呼吸感（半径 + 透明度）

按住时，圆圈不仅转动，还“呼吸”：

- 半径：`_radiusForSeconds()` 直接返回 `_baseRadius * _breathScale.value`
- 透明度：`_opacityForSeconds()` 返回 `_breathOpacity.value`

`_breathController` 是一个 **12 秒**的循环动画 (`_breathDuration = 12s`)：

- Scale: 1.0 → 1.12 → 1.0（带短暂停顿）
- Opacity: 0.60 → 0.75 → 0.60（同步节奏）

> 调参建议：
> - 想更明显的“鼓动感”：增大 `_breathScaleMax` 或提高 `_breathOpacityMax`。
> - 想更轻柔：缩小 `Scale` 幅度，降低 `Opacity` 变化范围。

### 2.4 Hold 状态 Ring 参数

按住时 `_currentRing()` 返回：

```
rotation: _rotationAngle
radius: _radiusForSeconds(t)
strokeWidth: _baseStroke
opacity: _opacityForSeconds(t)
sweep: _holdSweep  // 约 78% 圆周
```

`sweep` 默认是 `2π * 0.78`，因此显示的是一个未闭合的环。

> 调参建议：
> - 想更接近完整圆：增大 `_holdSweep` 比例。
> - 想更“缺口感”：降低 `_holdSweep`。

---

## 3) 松手后的“收回”逻辑（Release 动画）

松手触发 `_onPressEnd()`：

1. 停止计时与呼吸动画。
2. 记录当前视觉状态为“起始姿态”：
   - `_releaseStartRotation`
   - `_releaseStartRadius`
   - `_releaseStartOpacity`
   - `_releaseStartStroke`
   - `_releaseStartSweep`
3. 播放 `_releaseController`（总时长 400ms）。

### 3.1 Release 分段结构

释放动画分两段：

- **Phase A：闭合弧线（0 → 120ms）**
- **Phase B：缩小 + 淡出（120ms → 400ms）**

其中 `closePhaseT = 120 / 400 = 0.3`。

### 3.2 Phase A：弧线闭合

当 `t <= closePhaseT`：

```
sweep: lerp(_releaseStartSweep, 2π, easeOutCubic(t / closePhaseT))
```

因此弧线从 78% 圆周逐渐补齐到完整圆。

### 3.3 Phase B：收缩 + 变细 + 消失

当 `t > closePhaseT`：

```
collapseT = (t - closePhaseT) / (1 - closePhaseT)

radius     = lerp(_releaseStartRadius, _baseRadius * 0.85, collapseT)
strokeWidth= lerp(_releaseStartStroke, 0.0, collapseT)
opacity    = lerp(_releaseStartOpacity, 0.0, collapseT)
```

视觉效果：
- 圆缩到 85% 的大小
- 线宽收缩到 0
- 透明度归零

最终完全消失，并触发 `onRelease` 回调。

> 调参建议：
> - 想更“快收回”：缩短 `_releaseDuration` 或 `_releaseCloseDuration`。
> - 想更“干净利落”：把 `_releaseScaleMin` 调小（如 0.8）。
> - 想更“温柔”：把 `_releaseScaleMin` 调大（如 0.92），并延长 `_releaseDuration`。

---

## 4) 关键参数一览（集中调节）

| 参数 | 作用 | 默认值 |
|---|---|---:|
| `_rotationCycleSeconds` | 转速循环周期 | 6.0s |
| `_rotationStage1Seconds` | Stage1 时长 | 0.6s |
| `_rotationStage2Seconds` | Stage2 时长 | 1.8s |
| `_rotationStage3Seconds` | Stage3 时长 | 1.2s |
| `_rotationStage4Seconds` | Stage4 时长 | 2.4s |
| `_rotationStartDegPerSec` | 初速 | 80 |
| `_rotationPeakDegPerSec` | 峰值速度 | 160 |
| `_rotationMidLowDegPerSec` | 中低速度 | 70 |
| `_rotationMidHighDegPerSec` | 中高速度 | 140 |
| `_rotationEndDegPerSec` | 末端速度 | 60 |
| `_holdSweep` | 按住时弧度长度 | 78% 圆周 |
| `_breathDuration` | 呼吸周期 | 12s |
| `_breathScaleMax` | 最大呼吸缩放 | 1.12 |
| `_breathOpacityMin` | 呼吸最小透明度 | 0.60 |
| `_breathOpacityMax` | 呼吸最大透明度 | 0.75 |
| `_releaseDuration` | 释放总时长 | 400ms |
| `_releaseCloseDuration` | 闭合阶段时长 | 120ms |
| `_releaseScaleMin` | 收缩最小比例 | 0.85 |

---

## 5) 时间线简图（逻辑总览）

```
按住开始
  ├─ 启动 Stopwatch + Ticker
  ├─ rotationAngle 按循环转速增长
  └─ 呼吸动画驱动 radius/opacity

松手
  ├─ 停止 Stopwatch/Ticker/呼吸
  ├─ 保存当前 Ring 作为 releaseStart
  └─ 释放动画 400ms
       ├─ 0~120ms：弧线闭合 → 整圆
       └─ 120~400ms：缩小 + 变细 + 淡出
  → 完成后 onRelease 回调
```

---

如需我帮你调参，给出你想要的目标感受（更轻、更急、更厚、更柔等）即可。
