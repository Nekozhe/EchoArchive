/**
 * 存档服务：基于 Preferences 的本地持久化
 * 设计要点：
 * 1. 存盘带 schemaVersion，版本不匹配时降级为新档而不是崩溃
 * 2. 所有读写都做异常兜底，读失败返回新档，保证应用仍可启动
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GameState, newGameState, SAVE_KEY, SAVE_VERSION } from '../model/GameTypes';

const DOMAIN: number = 0x0001;
const TAG: string = 'SaveService';
const STORE_NAME: string = 'echo_game';

export class SaveService {
  private static context: common.UIAbilityContext | undefined = undefined;
  private static store: preferences.Preferences | undefined = undefined;

  /** 在 EntryAbility.onCreate 中注入上下文 */
  static init(context: common.UIAbilityContext): void {
    SaveService.context = context;
    SaveService.store = undefined;
  }

  private static async getStore(): Promise<preferences.Preferences> {
    if (SaveService.store !== undefined) {
      return SaveService.store;
    }
    const ctx: common.UIAbilityContext | undefined = SaveService.context;
    if (ctx === undefined) {
      throw new Error('SaveService 尚未初始化');
    }
    const store: preferences.Preferences = await preferences.getPreferences(ctx, STORE_NAME);
    SaveService.store = store;
    return store;
  }

  /** 读取存档；无存档或数据结构不可用时返回全新进度 */
  static async load(): Promise<GameState> {
    try {
      const store: preferences.Preferences = await SaveService.getStore();
      const raw: preferences.ValueType = await store.get(SAVE_KEY, '');
      const text: string = typeof raw === 'string' ? raw : '';
      if (text.length === 0) {
        return newGameState();
      }
      const parsed: GameState = JSON.parse(text) as GameState;
      if (!SaveService.isValid(parsed)) {
        hilog.warn(DOMAIN, TAG, '存档结构不兼容，降级为新档');
        return newGameState();
      }
      return parsed;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '读取存档失败: %{public}s', JSON.stringify(err));
      return newGameState();
    }
  }

  /** 写入存档 */
  static async save(state: GameState): Promise<void> {
    try {
      const store: preferences.Preferences = await SaveService.getStore();
      state.updatedAt = Date.now();
      await store.put(SAVE_KEY, JSON.stringify(state));
      await store.flush();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '写入存档失败: %{public}s', JSON.stringify(err));
    }
  }

  /** 清空存档（重开一局） */
  static async clear(): Promise<void> {
    try {
      const store: preferences.Preferences = await SaveService.getStore();
      await store.delete(SAVE_KEY);
      await store.flush();
    } catch (err) {
      hilog.error(DOMAIN, TAG, '清空存档失败: %{public}s', JSON.stringify(err));
    }
  }

  /** 是否存在有效存档 */
  static async hasSave(): Promise<boolean> {
    try {
      const state: GameState = await SaveService.load();
      return state.doneEvents.length > 0 || state.ownedClues.length > 0;
    } catch (err) {
      return false;
    }
  }

  /** 存档结构校验：字段缺失或版本不一致都视为无效 */
  private static isValid(state: GameState): boolean {
    if (state === null || state === undefined) {
      return false;
    }
    if (state.schemaVersion !== SAVE_VERSION) {
      return false;
    }
    if (!Array.isArray(state.ownedClues) || !Array.isArray(state.doneEvents)
      || !Array.isArray(state.visitedScenes)) {
      return false;
    }
    if (typeof state.trust !== 'number') {
      return false;
    }
    return true;
  }
}
