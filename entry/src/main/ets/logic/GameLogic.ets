/**
 * 核心业务规则（纯函数，不依赖 UI 与存储，可直接单元测试）
 */
import { Clue, DeductionSlots, EventNode, GameState, JudgeResult, newGameState } from '../model/GameTypes';
import { findClue } from '../data/CaseData';

/** 是否已获得某条线索 */
export function hasClue(state: GameState, clueId: string): boolean {
  return state.ownedClues.indexOf(clueId) >= 0;
}

/** 是否已获得全部指定线索 */
export function ownsAll(state: GameState, clueIds: string[]): boolean {
  if (clueIds.length === 0) {
    return true;
  }
  for (let i = 0; i < clueIds.length; i++) {
    if (!hasClue(state, clueIds[i])) {
      return false;
    }
  }
  return true;
}

/** 是否已获得任意一条指定线索 */
export function ownsAny(state: GameState, clueIds: string[]): boolean {
  if (clueIds.length === 0) {
    return true;
  }
  for (let i = 0; i < clueIds.length; i++) {
    if (hasClue(state, clueIds[i])) {
      return true;
    }
  }
  return false;
}

/** 事件节点是否已执行 */
export function isEventDone(state: GameState, eventId: string): boolean {
  return state.doneEvents.indexOf(eventId) >= 0;
}

/**
 * 判断事件节点当前是否可触发
 * 规则：未执行过（若 once）+ 线索前置全部满足 + 任一满足项成立 + 信任度达标
 */
export function canTrigger(state: GameState, node: EventNode): boolean {
  if (node.once && isEventDone(state, node.id)) {
    return false;
  }
  if (!ownsAll(state, node.requires)) {
    return false;
  }
  if (!ownsAny(state, node.requiresAny)) {
    return false;
  }
  if (state.trust < node.requireTrust) {
    return false;
  }
  return true;
}

/**
 * 执行事件节点，返回新的进度对象（不修改入参，便于测试与撤销）
 */
export function applyEvent(state: GameState, node: EventNode): GameState {
  const next: GameState = copyState(state);
  if (next.doneEvents.indexOf(node.id) < 0) {
    next.doneEvents.push(node.id);
  }
  for (let i = 0; i < node.grantClues.length; i++) {
    const id: string = node.grantClues[i];
    if (next.ownedClues.indexOf(id) < 0) {
      next.ownedClues.push(id);
    }
  }
  next.trust = next.trust + node.grantTrust;
  next.updatedAt = Date.now();
  return next;
}

/** 深拷贝进度对象 */
export function copyState(state: GameState): GameState {
  const next: GameState = newGameState();
  next.schemaVersion = state.schemaVersion;
  next.ownedClues = state.ownedClues.slice();
  next.visitedScenes = state.visitedScenes.slice();
  next.doneEvents = state.doneEvents.slice();
  next.trust = state.trust;
  next.attemptCount = state.attemptCount;
  next.endingId = state.endingId;
  next.updatedAt = state.updatedAt;
  return next;
}

/** 线索数量是否已解锁推理台 */
export function canOpenBoard(state: GameState, threshold: number): boolean {
  return state.ownedClues.length >= threshold;
}

/** 线索板里该线索是否可见（未获得时显示为未解锁） */
export function isClueVisible(state: GameState, clue: Clue): boolean {
  return hasClue(state, clue.id);
}

/**
 * 推理判定（核心业务规则）
 * 判定顺序：完整性 → 物证合法性 → 人物正确性 → 时间与物证是否构成完整证据链
 */
export function judgeDeduction(state: GameState, slots: DeductionSlots): JudgeResult {
  if (slots.person === '' || slots.period === '' || slots.evidence === '') {
    return { ok: false, endingId: '', reason: '假设不完整：人物、时段、物证都要选' };
  }
  if (findClue(slots.evidence) === undefined) {
    return { ok: false, endingId: '', reason: '这条物证不存在' };
  }
  if (!hasClue(state, slots.evidence)) {
    return { ok: false, endingId: '', reason: '这条物证你还没有拿到' };
  }
  if (slots.person !== 'A') {
    return { ok: true, endingId: 'END3', reason: '你作出了指认' };
  }
  if (slots.period === 'P2' && slots.evidence === 'C7') {
    return { ok: true, endingId: 'END1', reason: '证据链完整' };
  }
  return { ok: true, endingId: 'END2', reason: '指认成立，但证据链不完整' };
}
