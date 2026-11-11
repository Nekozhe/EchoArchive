/**
 * 案情静态数据：场景、线索、关系人、对话、结局、推理选项
 * 文案改动只需修改本文件，不需要动页面代码。
 */
import { Clue, DialogDef, EndingDef, EventNode, NpcDef, OptionItem, SceneDef } from '../model/GameTypes';

/** 三个可探索场景 */
export const SCENES: SceneDef[] = [
  { id: 'S1', name: '302 实验室', hint: '答辩前夜的最后检查点' },
  { id: 'S2', name: '值班室与走廊', hint: '门禁记录与监控都在这里' },
  { id: 'S3', name: '实验楼天台', hint: '风很大，没人愿意上来' }
];

/** 8 条线索（其中 5 条为关键线索） */
export const CLUES: Clue[] = [
  {
    id: 'C1', name: '电源线切口', keyClue: false, sceneId: 'S1',
    desc: '机箱电源线是被剪断的，切口平整，不像徒手扯断。动手的人带了工具。'
  },
  {
    id: 'C2', name: '门禁刷卡记录', keyClue: true, sceneId: 'S1',
    desc: '23:47 有一张卡刷开了 302，登记卡号尾号 0417。系统没有记录第二次刷卡。'
  },
  {
    id: 'C3', name: '二手主板快递单', keyClue: true, sceneId: 'S1',
    desc: '垃圾桶里的快递单，收件人是 A，物品写着「工控主板（二手）」，三天前签收。'
  },
  {
    id: 'C4', name: '监控离线时段', keyClue: true, sceneId: 'S2',
    desc: '23:00 到 00:20 走廊摄像头没有画面。管理员说那两天硬盘满了，没在意。'
  },
  {
    id: 'C5', name: '消防通道拖拽痕', keyClue: false, sceneId: 'S2',
    desc: '水泥地上有两道新刮痕，从消防门一直延伸到楼梯口。'
  },
  {
    id: 'C6', name: '外卖小票', keyClue: true, sceneId: 'S2',
    desc: '23:30 的外卖小票，备注「放 302 门口」，下单人是 B。'
  },
  {
    id: 'C7', name: '主板残片', keyClue: true, sceneId: 'S2',
    desc: 'B 交出来的残片，焊点粗糙、有明显补焊痕迹，不是原厂板。'
  },
  {
    id: 'C8', name: '机箱外壳', keyClue: false, sceneId: 'S3',
    desc: '外壳塞在水箱后面，主板和硬盘都被拆走，固定螺丝还留在槽里。'
  }
];

/** 三位关系人 */
export const NPCS: NpcDef[] = [
  { id: 'A', name: 'A', role: '队友 · 负责硬件' },
  { id: 'B', name: 'B', role: '队友 · 负责代码' },
  { id: 'C', name: 'C', role: '实验室管理员' }
];

/** 场景内的可触发事件（前 10 个探索节点） */
export const EVENTS: EventNode[] = [
  {
    id: 'E01', sceneId: 'S1', title: '检查工作台', brief: '原型机原来摆在这张桌上，现在只剩底座。',
    requires: [], requiresAny: [], requireTrust: 0,
    grantClues: ['C1'], grantTrust: 0, dialogId: '', once: true
  },
  {
    id: 'E02', sceneId: 'S1', title: '查看门禁面板', brief: '实验室门口的刷卡器还亮着，记录能导出。',
    requires: [], requiresAny: [], requireTrust: 0,
    grantClues: ['C2'], grantTrust: 0, dialogId: '', once: true
  },
  {
    id: 'E03', sceneId: 'S1', title: '翻看垃圾桶', brief: '保洁还没收，里面有几张纸。',
    requires: [], requiresAny: [], requireTrust: 0,
    grantClues: ['C3'], grantTrust: 0, dialogId: '', once: true
  },
  {
    id: 'E04', sceneId: 'S2', title: '与管理员的对话', brief: 'C 坐在值班室里，看起来比你还紧张。',
    requires: [], requiresAny: [], requireTrust: 0,
    grantClues: [], grantTrust: 1, dialogId: 'D1', once: true
  },
  {
    id: 'E05', sceneId: 'S2', title: '调看监控回放', brief: '需要门禁记录，才能说清要看哪个时段。',
    requires: ['C2'], requiresAny: [], requireTrust: 1,
    grantClues: ['C4'], grantTrust: 0, dialogId: 'D2', once: true
  },
  {
    id: 'E06', sceneId: 'S2', title: '查看消防通道', brief: '走廊尽头那扇门平时是锁着的。',
    requires: ['C4'], requiresAny: [], requireTrust: 0,
    grantClues: ['C5'], grantTrust: 0, dialogId: '', once: true
  },
  {
    id: 'E07', sceneId: 'S2', title: '与 B 的对话', brief: 'B 说当晚不在楼里，但眼神一直在躲。',
    requires: [], requiresAny: [], requireTrust: 0,
    grantClues: ['C6'], grantTrust: 0, dialogId: 'D3', once: true
  },
  {
    id: 'E08', sceneId: 'S2', title: '让 B 交出主板残片', brief: '小票上的时间和 B 的说法对不上。',
    requires: ['C6'], requiresAny: [], requireTrust: 0,
    grantClues: ['C7'], grantTrust: 0, dialogId: 'D4', once: true
  },
  {
    id: 'E09', sceneId: 'S3', title: '搜索水箱后侧', brief: '天台上唯一能藏东西的角落。',
    requires: ['C5'], requiresAny: [], requireTrust: 0,
    grantClues: ['C8'], grantTrust: 0, dialogId: '', once: true
  },
  {
    id: 'E10', sceneId: 'S3', title: '与 A 对质', brief: 'A 说整晚都在宿舍改代码。',
    requires: [], requiresAny: ['C3', 'C8'], requireTrust: 0,
    grantClues: [], grantTrust: 0, dialogId: 'D5', once: true
  }
];

/** 对话脚本 */
export const DIALOGS: DialogDef[] = [
  {
    id: 'D1', npcId: 'C',
    lines: [
      '「那晚我十点就走了……门应该是锁了的。」',
      '「刷卡记录？系统里有，但我不太会导。」',
      '你把门禁面板的记录调出来给他看，他的表情松了一点。',
      '「行吧，你要看监控，我带你去。别跟老师说是我忘锁门。」'
    ]
  },
  {
    id: 'D2', npcId: 'C',
    lines: [
      '回放画面在 23:00 整变成一片雪花，直到 00:20 才恢复。',
      '「硬盘满了就会这样，自动覆盖。」',
      '「不过……」他顿了一下，「那天我下午刚清过盘。」'
    ]
  },
  {
    id: 'D3', npcId: 'B',
    lines: [
      '「我整晚都在宿舍，没去过实验室。」',
      '你注意到他桌角压着一张外卖小票。',
      '「那是……中午的。」他说得太快了。'
    ]
  },
  {
    id: 'D4', npcId: 'B',
    lines: [
      '你把小票放在他面前：23:30，备注「放 302 门口」。',
      '他沉默了很久，从书包侧袋里摸出一块板子。',
      '「我进去的时候，机箱已经是空的了。」',
      '「这块是掉在地上的一角，我捡起来没敢说。」'
    ]
  },
  {
    id: 'D5', npcId: 'A',
    lines: [
      '「我改代码改到三点，室友能作证。」',
      '你把快递单推过去，他的手指停了一下。',
      '「那是我自己换着玩的板子，跟比赛机器没关系。」',
      '他说这话的时候，没有看你的眼睛。'
    ]
  }
];

/** 三种结局 */
export const ENDINGS: EndingDef[] = [
  {
    id: 'END1', title: '结局一 · 焊点',
    text: '你把主板残片和快递单一起放在桌上。A 看了很久，最后伸手把残片翻了个面——\n\n' +
      '「原厂板答辩前一周烧了。我买了块二手的顶上，焊功太差，装回去的时候把供电脚焊断了。」\n\n' +
      '「我想着先把整机搬走，拖到答辩后再说是运输损坏。天台那晚风太大，我手一直在抖。」\n\n' +
      '案子结了。第二天你路过 302，门开着，桌上摆着一块新的原厂板——标签还没撕。'
  },
  {
    id: 'END2', title: '结局二 · 断链',
    text: '你指对了人，但拿不出能把他和那晚连起来的东西。\n\n' +
      'A 承认换过主板，也承认去过天台，但坚持「机器不是我搬走的」。\n\n' +
      '辅导员最后按「设备管理不善」处理，赔偿由三个人平摊。\n\n' +
      '你知道不是这样。可推理这件事，光知道没有用。'
  },
  {
    id: 'END3', title: '结局三 · 替罪羊',
    text: '你指向了另一个人。\n\n' +
      '调查草草收场，处分下来得很快。那个人在班群里发了一句「随便吧」，然后退了群。\n\n' +
      '一个月后，你在旧硬盘里翻到一段没被覆盖的监控碎片：23:47，一个抱着纸箱的身影侧身进了消防通道。\n\n' +
      '你把视频存了下来，没有发出去。'
  }
];

/** 推理台：人物选项 */
export const PERSON_OPTIONS: OptionItem[] = [
  { id: 'A', label: 'A · 硬件队友' },
  { id: 'B', label: 'B · 代码队友' },
  { id: 'C', label: 'C · 管理员' }
];

/** 推理台：时间段选项 */
export const PERIOD_OPTIONS: OptionItem[] = [
  { id: 'P1', label: '23:00 – 23:40' },
  { id: 'P2', label: '23:40 – 00:20' },
  { id: 'P3', label: '00:20 – 07:00' }
];

/** 推理台：物证选项（只展示已获得的关键线索） */
export const EVIDENCE_OPTIONS: OptionItem[] = [
  { id: 'C3', label: '二手主板快递单' },
  { id: 'C4', label: '监控离线时段' },
  { id: 'C6', label: '外卖小票' },
  { id: 'C7', label: '主板残片' }
];

/** 工具：按 id 取线索 */
export function findClue(id: string): Clue | undefined {
  return CLUES.find((item: Clue) => item.id === id);
}

/** 工具：按 id 取对话 */
export function findDialog(id: string): DialogDef | undefined {
  return DIALOGS.find((item: DialogDef) => item.id === id);
}

/** 工具：按 id 取结局 */
export function findEnding(id: string): EndingDef | undefined {
  return ENDINGS.find((item: EndingDef) => item.id === id);
}

/** 工具：按 id 取场景 */
export function findScene(id: string): SceneDef | undefined {
  return SCENES.find((item: SceneDef) => item.id === id);
}

/** 工具：按 id 取关系人 */
export function findNpc(id: string): NpcDef | undefined {
  return NPCS.find((item: NpcDef) => item.id === id);
}
