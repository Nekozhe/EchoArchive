/**
 * 核心业务规则单元测试
 * 覆盖三类用例：正常流程 / 边界条件 / 异常输入
 * 运行方式：DevEco 右键本文件 > Run，或右下角 Test 面板执行
 */
import { describe, it, expect } from '@ohos/hypium';
import {
  DeductionSlots, EventNode, GameState, JudgeResult, newGameState, SAVE_VERSION
} from '../../../main/ets/model/GameTypes';
import { applyEvent, canTrigger, hasClue, judgeDeduction } from '../../../main/ets/logic/GameLogic';
import { EVENTS } from '../../../main/ets/data/CaseData';
import { SaveService } from '../../../main/ets/service/SaveService';

/** 按 id 取事件节点，找不到直接抛错，避免测试静默通过 */
function node(id: string): EventNode {
  const found: EventNode | undefined = EVENTS.find((item: EventNode) => item.id === id);
  if (found === undefined) {
    throw new Error(`事件节点不存在: ${id}`);
  }
  return found;
}

/** 构造推理槽 */
function slots(person: string, period: string, evidence: string): DeductionSlots {
  const result: DeductionSlots = { person: person, period: period, evidence: evidence };
  return result;
}

export default function gameLogicTest() {
  describe('GameLogic', () => {
    /**
     * 用例 1（正常）：初次调查 302 实验室，节点可触发且正确发放线索
     */
    it('normal_explore_grants_clue', 0, () => {
      let state: GameState = newGameState();
      const target: EventNode = node('E01');
      expect(canTrigger(state, target)).assertTrue();

      state = applyEvent(state, target);
      expect(state.ownedClues.length).assertEqual(1);
      expect(hasClue(state, 'C1')).assertTrue();
      expect(state.doneEvents.indexOf('E01') >= 0).assertTrue();
    });

    /**
     * 用例 2（边界）：线索前置不满足时节点受限，补齐线索后立刻可用
     */
    it('boundary_locked_until_clue_owned', 0, () => {
      let state: GameState = newGameState();
      const target: EventNode = node('E08');

      // 还没有外卖小票 C6，不能要求 B 交出残片
      expect(hasClue(state, 'C6')).assertFalse();
      expect(canTrigger(state, target)).assertFalse();

      // 先与 B 对话拿到 C6
      state = applyEvent(state, node('E07'));
      expect(hasClue(state, 'C6')).assertTrue();
      expect(canTrigger(state, target)).assertTrue();

      // 重复执行后 once 生效，不再可触发
      state = applyEvent(state, target);
      expect(canTrigger(state, target)).assertFalse();
    });

    /**
     * 用例 3（边界）：管理员信任度门槛，线索够了但信任不足仍然受限
     */
    it('boundary_requires_admin_trust', 0, () => {
      let state: GameState = newGameState();
      const monitor: EventNode = node('E05');

      // 只有门禁记录，信任度为 0
      state = applyEvent(state, node('E02'));
      expect(hasClue(state, 'C2')).assertTrue();
      expect(state.trust).assertEqual(0);
      expect(canTrigger(state, monitor)).assertFalse();

      // 与管理员对话后信任度 +1，门槛达成
      state = applyEvent(state, node('E04'));
      expect(state.trust).assertEqual(1);
      expect(canTrigger(state, monitor)).assertTrue();
    });

    /**
     * 用例 4（异常）：推理槽不完整或使用未获得的物证时，必须拒绝而不是崩溃
     */
    it('abnormal_incomplete_deduction', 0, () => {
      const state: GameState = newGameState();

      const empty: JudgeResult = judgeDeduction(state, slots('', '', ''));
      expect(empty.ok).assertFalse();
      expect(empty.reason.length > 0).assertTrue();

      // C7 尚未获得，即使填了也不能进入判定
      const notOwned: JudgeResult = judgeDeduction(state, slots('A', 'P2', 'C7'));
      expect(notOwned.ok).assertFalse();

      // 不存在的物证 id
      const invalid: JudgeResult = judgeDeduction(state, slots('A', 'P2', 'C99'));
      expect(invalid.ok).assertFalse();
    });

    /**
     * 用例 5（正常）：三种结局分支的判定边界
     */
    it('normal_three_ending_branches', 0, () => {
      const state: GameState = newGameState();
      // 直接构造「四条关键线索都已获得」的进度，聚焦判定分支本身
      state.ownedClues = ['C3', 'C4', 'C6', 'C7'];

      // 人物 + 时段 + 物证 三者吻合 → 真相结局
      const truth: JudgeResult = judgeDeduction(state, slots('A', 'P2', 'C7'));
      expect(truth.ok).assertTrue();
      expect(truth.endingId).assertEqual('END1');

      // 指对人但证据链不完整 → 断链结局
      const broken: JudgeResult = judgeDeduction(state, slots('A', 'P1', 'C7'));
      expect(broken.ok).assertTrue();
      expect(broken.endingId).assertEqual('END2');

      // 指错人 → 替罪羊结局
      const wrong: JudgeResult = judgeDeduction(state, slots('B', 'P2', 'C7'));
      expect(wrong.ok).assertTrue();
      expect(wrong.endingId).assertEqual('END3');
    });

    /**
     * 用例 6（异常）：存档解析容错，损坏或版本不匹配必须降级为新档
     */
    it('abnormal_corrupted_save_fallback', 0, () => {
      // 空文本
      expect(SaveService.parse('').ownedClues.length).assertEqual(0);

      // 非法 JSON
      expect(SaveService.parse('not-a-json').doneEvents.length).assertEqual(0);

      // 缺少必填字段
      expect(SaveService.parse('{"schemaVersion":1}').trust).assertEqual(0);

      // 版本不匹配：旧档结构不可信，降级为新档
      const oldVersion: string = '{"schemaVersion":99,"ownedClues":["C1"],"visitedScenes":[],' +
        '"doneEvents":[],"trust":0,"attemptCount":0,"endingId":"","updatedAt":0}';
      expect(SaveService.parse(oldVersion).ownedClues.length).assertEqual(0);

      // 正常存档可完整往返
      const state: GameState = newGameState();
      state.schemaVersion = SAVE_VERSION;
      state.ownedClues = ['C1', 'C2'];
      state.trust = 1;
      const restored: GameState = SaveService.parse(JSON.stringify(state));
      expect(restored.ownedClues.length).assertEqual(2);
      expect(restored.trust).assertEqual(1);
    });
  });
}
