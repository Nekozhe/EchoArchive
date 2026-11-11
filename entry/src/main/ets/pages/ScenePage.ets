/**
 * 场景探索页
 * 职责：三个场景切换、事件节点触发、线索获取反馈、对话播放
 * 关键设计：所有节点都带前置条件，不满足时给出具体原因，而不是只禁用按钮
 */
import { router, promptAction } from '@kit.ArkUI';
import {
  CLUE_TOTAL, EventNode, GameState, newGameState, SceneDef, UNLOCK_BOARD_CLUES
} from '../model/GameTypes';
import { applyEvent, canOpenBoard, canTrigger, isEventDone } from '../logic/GameLogic';
import { EVENTS, findClue, findDialog, findNpc, SCENES } from '../data/CaseData';
import { SaveService } from '../service/SaveService';
import {
  C_ACCENT, C_ACCENT_DARK, C_BG, C_BORDER, C_CARD, C_CARD_LIGHT, C_OK, C_SUB, C_TEXT
} from '../common/Theme';

@Entry
@Component
struct ScenePage {
  @State gs: GameState = newGameState();
  @State sceneIndex: number = 0;
  @State dialogLines: string[] = [];
  @State dialogNpc: string = '';
  @State dialogIndex: number = 0;
  @State pendingClues: string[] = [];
  private ready: boolean = false;

  aboutToAppear(): void {
    SaveService.load().then((state: GameState) => {
      this.gs = state;
      this.ready = true;
    });
  }

  private currentSceneId(): string {
    return SCENES[this.sceneIndex].id;
  }

  private nodesOfCurrentScene(): EventNode[] {
    const sid: string = this.currentSceneId();
    return EVENTS.filter((item: EventNode) => item.sceneId === sid);
  }

  private markVisited(): void {
    const sid: string = this.currentSceneId();
    if (this.gs.visitedScenes.indexOf(sid) < 0) {
      const next: GameState = this.gs;
      next.visitedScenes.push(sid);
      this.gs = next;
      SaveService.save(this.gs);
    }
  }

  private statusOf(node: EventNode): string {
    if (isEventDone(this.gs, node.id)) {
      return '已完成';
    }
    return canTrigger(this.gs, node) ? '可调查' : '受限';
  }

  private lockHint(node: EventNode): string {
    for (let i = 0; i < node.requires.length; i++) {
      if (this.gs.ownedClues.indexOf(node.requires[i]) < 0) {
        const clue = findClue(node.requires[i]);
        const name: string = clue === undefined ? '未知线索' : clue.name;
        return `需要先获得「${name}」`;
      }
    }
    if (node.requiresAny.length > 0) {
      let matched: boolean = false;
      for (let i = 0; i < node.requiresAny.length; i++) {
        if (this.gs.ownedClues.indexOf(node.requiresAny[i]) >= 0) {
          matched = true;
          break;
        }
      }
      if (!matched) {
        return '手上的线索还不够，先去别处看看';
      }
    }
    if (this.gs.trust < node.requireTrust) {
      return '需要先取得管理员的信任';
    }
    return '暂不可调查';
  }

  private onNodeTap(node: EventNode): void {
    if (isEventDone(this.gs, node.id)) {
      promptAction.showToast({ message: '这里已经调查过了' });
      return;
    }
    if (!canTrigger(this.gs, node)) {
      promptAction.showToast({ message: this.lockHint(node) });
      return;
    }
    const next: GameState = applyEvent(this.gs, node);
    this.gs = next;
    SaveService.save(next);
    this.pendingClues = node.grantClues.slice();

    if (node.dialogId !== '') {
      const dialog = findDialog(node.dialogId);
      if (dialog !== undefined) {
        const npc = findNpc(dialog.npcId);
        this.dialogNpc = npc === undefined ? '' : `${npc.name} · ${npc.role}`;
        this.dialogLines = dialog.lines.slice();
        this.dialogIndex = 0;
        return;
      }
    }
    this.reportGain();
  }

  private reportGain(): void {
    if (this.pendingClues.length === 0) {
      promptAction.showToast({ message: '调查完成' });
      return;
    }
    const names: string[] = [];
    for (let i = 0; i < this.pendingClues.length; i++) {
      const clue = findClue(this.pendingClues[i]);
      if (clue !== undefined) {
        names.push(clue.name);
      }
    }
    this.pendingClues = [];
    promptAction.showToast({ message: `获得线索：${names.join('、')}` });
  }

  private advanceDialog(): void {
    if (this.dialogIndex < this.dialogLines.length - 1) {
      this.dialogIndex = this.dialogIndex + 1;
      return;
    }
    this.dialogLines = [];
    this.dialogNpc = '';
    this.dialogIndex = 0;
    this.reportGain();
  }

  private openBoard(): void {
    router.pushUrl({ url: 'pages/ClueBoardPage' });
  }

  private openDeduction(): void {
    if (!canOpenBoard(this.gs, UNLOCK_BOARD_CLUES)) {
      promptAction.showToast({ message: `至少收集 ${UNLOCK_BOARD_CLUES} 条线索才能开始推理` });
      return;
    }
    router.pushUrl({ url: 'pages/DeductionPage' });
  }

  @Builder
  sceneTab(index: number) {
    Text(SCENES[index].name)
      .fontSize(13)
      .fontColor(this.sceneIndex === index ? C_ACCENT_DARK : C_SUB)
      .fontWeight(this.sceneIndex === index ? FontWeight.Medium : FontWeight.Normal)
      .textAlign(TextAlign.Center)
      .layoutWeight(1)
      .height(38)
      .borderRadius(10)
      .backgroundColor(this.sceneIndex === index ? C_ACCENT : Color.Transparent)
      .onClick(() => {
        this.sceneIndex = index;
        this.markVisited();
      })
  }

  @Builder
  eventCard(node: EventNode) {
    Column({ space: 8 }) {
      Row() {
        Text(node.title).fontSize(15).fontColor(C_TEXT).fontWeight(FontWeight.Medium)
        Blank()
        Text(this.statusOf(node))
          .fontSize(11)
          .fontColor(this.statusOf(node) === '可调查' ? C_OK : C_SUB)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.statusOf(node) === '可调查' ? '#1E3A30' : '#232C39')
          .borderRadius(6)
      }
      .width('100%')

      Text(node.brief)
        .fontSize(13)
        .fontColor(C_SUB)
        .lineHeight(20)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(C_CARD)
    .borderRadius(14)
    .border({ width: 1, color: isEventDone(this.gs, node.id) ? C_BORDER : C_CARD_LIGHT })
    .opacity(isEventDone(this.gs, node.id) ? 0.55 : 1)
    .onClick(() => {
      this.onNodeTap(node);
    })
  }

  @Builder
  dialogLayer() {
    Column() {
      Blank()
      Column({ space: 14 }) {
        Text(this.dialogNpc).fontSize(12).fontColor(C_ACCENT).letterSpacing(1)
        Text(this.dialogLines[this.dialogIndex])
          .fontSize(15)
          .fontColor(C_TEXT)
          .lineHeight(26)
          .width('100%')
        Row() {
          Text(`${this.dialogIndex + 1} / ${this.dialogLines.length}`).fontSize(11).fontColor(C_SUB)
          Blank()
          Button() {
            Text(this.dialogIndex < this.dialogLines.length - 1 ? '继续' : '收起')
              .fontSize(13)
              .fontColor(C_ACCENT_DARK)
          }
          .height(34)
          .padding({ left: 18, right: 18 })
          .backgroundColor(C_ACCENT)
          .borderRadius(9)
          .onClick(() => {
            this.advanceDialog();
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor(C_CARD)
      .borderRadius({ topLeft: 20, topRight: 20 })
      .border({ width: 1, color: C_BORDER })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#AA000000')
    .onClick(() => {
      this.advanceDialog();
    })
  }

  build() {
    Stack() {
      Column() {
        // 顶部栏
        Row() {
          Text('‹').fontSize(26).fontColor(C_TEXT).width(30).onClick(() => {
            router.back();
          })
          Column({ space: 2 }) {
            Text('调查中').fontSize(15).fontColor(C_TEXT)
            Text(SCENES[this.sceneIndex].hint).fontSize(10).fontColor(C_SUB)
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Column({ space: 2 }) {
            Text(`${this.gs.ownedClues.length} / ${CLUE_TOTAL}`).fontSize(14).fontColor(C_ACCENT)
            Text('线索').fontSize(10).fontColor(C_SUB)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })

        // 场景切换
        Row({ space: 4 }) {
          ForEach(SCENES, (item: SceneDef, index: number) => {
            this.sceneTab(index)
          }, (item: SceneDef) => item.id)
        }
        .width('100%')
        .padding(4)
        .margin({ left: 20, right: 20, top: 0 })
        .backgroundColor(C_CARD)
        .borderRadius(12)

        // 事件列表
        Scroll() {
          Column({ space: 12 }) {
            Text('可调查的节点')
              .fontSize(11)
              .fontColor(C_SUB)
              .letterSpacing(2)
              .width('100%')
              .margin({ top: 14, bottom: 2 })

            ForEach(this.nodesOfCurrentScene(), (node: EventNode) => {
              this.eventCard(node)
            }, (node: EventNode) => node.id)

            Blank().height(12)
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)

        // 底部操作
        Row({ space: 12 }) {
          Button() {
            Text(`线索板 ${this.gs.ownedClues.length}`).fontSize(14).fontColor(C_TEXT)
          }
          .layoutWeight(1)
          .height(46)
          .backgroundColor(C_CARD)
          .borderRadius(12)
          .border({ width: 1, color: C_BORDER })
          .onClick(() => {
            this.openBoard();
          })

          Button() {
            Text(canOpenBoard(this.gs, UNLOCK_BOARD_CLUES) ? '开始推理' : '推理未解锁')
              .fontSize(14)
              .fontColor(canOpenBoard(this.gs, UNLOCK_BOARD_CLUES) ? C_ACCENT_DARK : C_SUB)
          }
          .layoutWeight(1)
          .height(46)
          .backgroundColor(canOpenBoard(this.gs, UNLOCK_BOARD_CLUES) ? C_ACCENT : C_CARD)
          .borderRadius(12)
          .border({ width: 1, color: C_BORDER })
          .onClick(() => {
            this.openDeduction();
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10, bottom: 18 })
      }
      .width('100%')
      .height('100%')

      if (this.dialogLines.length > 0) {
        this.dialogLayer()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C_BG)
  }
}
