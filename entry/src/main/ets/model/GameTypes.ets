/**
 * 游戏数据模型定义
 * 说明：所有类型集中定义，页面与业务逻辑只依赖本文件，便于替换文案与扩展剧情。
 */

/** 线索卡 */
export interface Clue {
  id: string;
  name: string;
  desc: string;
  /** 是否关键线索（影响推理台可用物证） */
  keyClue: boolean;
  /** 所属场景，用于线索板分组展示 */
  sceneId: string;
}

/** 场景内的事件节点 */
export interface EventNode {
  id: string;
  sceneId: string;
  title: string;
  brief: string;
  /** 触发前置：需要全部已获得的线索 id */
  requires: string[];
  /** 触发前置：以下线索满足任意一条即可 */
  requiresAny: string[];
  /** 触发前置：管理员信任度下限 */
  requireTrust: number;
  /** 触发后获得的线索 */
  grantClues: string[];
  /** 触发后增加的信任度 */
  grantTrust: number;
  /** 关联对话 id，空串表示无对话 */
  dialogId: string;
  /** 是否只能执行一次 */
  once: boolean;
}

/** 可探索场景 */
export interface SceneDef {
  id: string;
  name: string;
  hint: string;
}

/** 关系人 */
export interface NpcDef {
  id: string;
  name: string;
  role: string;
}

/** 对话脚本 */
export interface DialogDef {
  id: string;
  npcId: string;
  lines: string[];
}

/** 结局 */
export interface EndingDef {
  id: string;
  title: string;
  text: string;
}

/** 玩家进度（存盘主体） */
export interface GameState {
  /** 存档结构版本，用于旧档兼容判断 */
  schemaVersion: number;
  ownedClues: string[];
  visitedScenes: string[];
  doneEvents: string[];
  /** 管理员信任度 */
  trust: number;
  /** 提交假设的次数 */
  attemptCount: number;
  endingId: string;
  updatedAt: number;
}

/** 推理判定结果 */
export interface JudgeResult {
  ok: boolean;
  endingId: string;
  reason: string;
}

/** 推理槽内容 */
export interface DeductionSlots {
  person: string;
  period: string;
  evidence: string;
}

/** 选项定义（推理台与设置页复用） */
export interface OptionItem {
  id: string;
  label: string;
}

export const SAVE_KEY: string = 'game_state';
export const SAVE_VERSION: number = 1;
export const CLUE_TOTAL: number = 8;
export const UNLOCK_BOARD_CLUES: number = 4;

/** 创建一个全新的进度对象 */
export function newGameState(): GameState {
  const state: GameState = {
    schemaVersion: SAVE_VERSION,
    ownedClues: [],
    visitedScenes: [],
    doneEvents: [],
    trust: 0,
    attemptCount: 0,
    endingId: '',
    updatedAt: 0
  };
  return state;
}
