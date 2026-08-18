# DevFlow Pressure Scenarios

> 本文档供 AI 在运行时参考，不直接展示给用户。
> 每个场景描述：触发信号、正确行为（Required Behavior）、常见错误（Failure Pattern）。
> 当对话出现场景信号时，对照 Required Behavior 检查自己的下一步动作。

---

## 场景 1：「先放一放，继续下一个」

**信号：**
- 用户说「这个问题先放一放」「先跳过这个」「继续下一个」
- 当前有一个未解决的问题或阻塞项

**Required Behavior：**
1. 将该问题在 `open-issues.md` 中状态更新为 `paused`，若还没有条目则新增一条
2. 明确输出「已将「{问题描述}」标记为 paused，记录于 OI-{N}」
3. 干净地切换到下一个任务，不再提及该问题
4. 下次 `devflow:continue` 恢复时该条目会重新显示

**Failure Pattern：**
- 假装问题已解决，从 open-issues.md 中删除条目
- 每轮都重提该问题，阻碍主线推进
- 只在对话里说「这个问题先搁置」，不更新 open-issues.md（新会话后丢失）

---

## 场景 2：「文档做完了，是不是做完了」

**信号：**
- 用户问「需求/设计/方案是不是写完了」「可以算完成了吗」
- 文档看起来很完整，但运行时验证状态不明

**Required Behavior：**
1. 检查 `meta.json.stages` 的验证状态字段（`coded` / `locallyVerified` / `runtimeVerified`）
2. 检查 `tasks.md` 各任务的 `Verification` 字段
3. 明确区分阶段：文档完成 ≠ 代码完成 ≠ 本地验证通过 ≠ 运行时验证通过
4. 输出当前实际所处阶段，以及到「完成」还缺什么证据

**Failure Pattern：**
- 文档看起来完整就说「完成了」
- 把「代码审查通过（APPROVED）」当成「用户可见行为已验证」

---

## 场景 3：「多条验收反馈连续涌入」

**信号：**
- 用户连续发来多条产品/测试反馈
- 每条都是具体的问题点，而不是需求变更

**Required Behavior：**
1. 每条反馈作为独立的最小切片处理，一次只处理一条
2. 当前条完成（code_done + locally_verified）后再处理下一条
3. 对每条反馈判断属于：当前切片修复 / 补充方案 / 新切片
4. 每处修改后将 `变更记录` 写入 `spec/requirement.md`，反馈来源和影响范围标注清楚

**Failure Pattern：**
- 把所有反馈合并成一个「修复一批问题」的提交
- 在第一条还没验证前就开始修第二条
- 修完后不回写变更记录，失去溯源

---

## 场景 4：「接口字段语义不确定，能否继续」

**信号：**
- 某个接口字段的含义、枚举值或默认值不确定
- 用户想知道是否可以先继续推进

**Required Behavior：**
1. 判断属于哪类：HardBlocker（核心功能依赖此字段）还是 ControlledPass（可以先按默认值处理）
2. HardBlocker：明确说「这个字段不确认，无法推进 {具体功能}，需要先确认」
3. ControlledPass：在 `open-issues.md` 新增 assumption 条目，记录：当前假设是什么 / 影响哪个功能 / 恢复触发器（后端确认后重新评估）/ 假设失效时影响什么
4. 继续推进只在 ControlledPass 确认后

**Failure Pattern：**
- 假装字段语义已知，把推测写进实现
- 把所有字段不确定都当 HardBlocker，全部停下来等
- 记录了假设但没有写恢复触发器（后续无法追踪何时应重新评估）

---

## 场景 5：「新会话恢复，发现假设已失效」

**信号：**
- `devflow:continue` 展示的 `open-issues.md` 条目中，某个 assumption 的恢复触发器已发生
- 或用户说「之前假设 X，现在确认了不是这样」

**Required Behavior：**
1. 找到 open-issues.md 中对应的 assumption 条目
2. 检查该假设的「影响范围」字段，找出受影响的任务（`关联任务` 列）
3. 将受影响任务的 Verification 降级（若已验证，降回 code_done）
4. 在 open-issues.md 将该条目状态更新为 `resolved`，同时在 `spec/requirement.md` 变更记录中追加
5. 告知用户哪些任务需要重新验证

**Failure Pattern：**
- 直接开始修改代码，不先评估影响范围
- 把假设失效当成小修改处理，不更新 Verification 状态
- 关闭 open-issues.md 条目但不检查关联任务

---

## 场景 6：「这个需求改了一下」

**信号：**
- 用户描述了一个需求调整
- 不清楚这是 Minor 还是 Major 变更

**Required Behavior：**
1. 询问确认变更级别（不自行决定边界模糊的情况）：
   - Minor：UI 文案、单一字段、不影响架构
   - Major：影响核心流程、接口契约、模块拆分
2. 触发 `devflow:change` 流程，按变更级别回退状态机
3. 检查已完成任务中哪些在 CodeGraph 影响面内，更新回归义务

**Failure Pattern：**
- 默默修改已有文档，不走 `devflow:change`，不回退状态机
- 把 Major 变更当 Minor 处理，跳过重新设计
- 修改代码后不更新受影响任务的 Verification 字段

---

## 场景 7：「这几个功能能不能一起做」

**信号：**
- 用户想把多个功能点合并在一个切片里同时实现
- 这些功能点落地到不同模块或有不同验证路径

**Required Behavior：**
1. 检查这些功能点是否共享核心数据层或状态机——共享则可能合适放一个切片
2. 检查是否有独立的验证路径——有独立验证路径的应分切片
3. 如果功能点数量 ≥ 8 且属于同一大型需求，建议 Epic + 子工作项模式
4. 明确告知合并的风险：验证困难、失败时无法定位是哪个功能的问题

**Failure Pattern：**
- 因为用户要求就把所有功能一锅端，丧失切片验证的价值
- 把切片边界放得太细（每个函数一个切片），增加无谓开销

---

## 场景 8：「代码 review 过了，能提 MR 了吧」

**信号：**
- `devflow:review` 输出了 APPROVED
- 用户准备合并或提 MR

**Required Behavior：**
1. 检查四问门禁触发条件（任务数 ≥ 5 / open-issues 有 open 条目 / CG 影响面 ≥ 2 个模块）
2. 满足触发条件时：输出四问门禁，等待用户逐一回答后才展示合并选项
3. 用户跳过某问时：要求说明原因，记录到 review.md
4. 不满足触发条件时：直接展示合并选项

**Failure Pattern：**
- 把「审查通过」直接等同于「本地运行验证通过」
- 跳过四问门禁直接合并
- 四问全部默认 y 不实际检查状态
