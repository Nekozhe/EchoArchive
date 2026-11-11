/**
 * 委托页（首页）
 * 职责：展示案件简报、读取存档状态、发起或继续调查
 */
import { router, promptAction } from '@kit.ArkUI';
import { CLUE_TOTAL, GameState, newGameState } from '../model/GameTypes';
import { SaveService } from '../service/SaveService';
import { SCENES } from '../data/CaseData';
import { C_ACCENT, C_ACCENT_DARK, C_BG, C_BORDER, C_CARD, C_DANGER, C_SUB, C_TEXT } from '../common/Theme';

@Entry
@Component
struct Index {
  @State gs: GameState = newGameState();
  @State hasSave: boolean = false;
  @State ready: boolean = false;

  aboutToAppear(): void {
    this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  private refresh(): void {
    SaveService.load().then((state: GameState) => {
      this.gs = state;
      this.hasSave = state.doneEvents.length > 0 || state.ownedClues.length > 0;
      this.ready = true;
    });
  }

  private enterGame(): void {
    router.pushUrl({ url: 'pages/ScenePage' }).catch(() => {
      promptAction.showToast({ message: '页面跳转失败' });
    });
  }

  private onStartTap(): void {
    if (!this.hasSave) {
      this.enterGame();
      return;
    }
    AlertDialog.show({
      title: '重新调查',
      message: '当前进度会清空，重新从委托开始。确定吗？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确定重开',
        fontColor: C_DANGER,
        action: () => {
          SaveService.clear().then(() => {
            this.gs = newGameState();
            this.hasSave = false;
            this.enterGame();
          });
        }
      }
    });
  }

  @Builder
  briefCard() {
    Column({ space: 10 }) {
      Row() {
        Text('案件简报').fontSize(13).fontColor(C_ACCENT).letterSpacing(2)
        Blank()
        Text('CASE 0417').fontSize(11).fontColor(C_SUB)
      }
      .width('100%')

      Text('答辩前夜，302 实验室的竞赛原型机被搬走了。机箱第二天出现在天台，主板和硬盘不见了。')
        .fontSize(14)
        .fontColor(C_TEXT)
        .lineHeight(23)

      Text('辅导员找到你：「你是他们同学，说话比我管用。三天，给我个说法。」')
        .fontSize(14)
        .fontColor(C_SUB)
        .lineHeight(23)
    }
    .width('100%')
    .padding(18)
    .backgroundColor(C_CARD)
    .borderRadius(16)
    .border({ width: 1, color: C_BORDER })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  progressCard() {
    Column({ space: 8 }) {
      Row() {
        Text('上次进度').fontSize(12).fontColor(C_SUB)
        Blank()
        Text(`${this.gs.ownedClues.length} / ${CLUE_TOTAL} 条线索`).fontSize(12).fontColor(C_ACCENT)
      }
      .width('100%')

      Row() {
        Text(this.gs.endingId === '' ? '调查进行中' : '已完成一次指认')
          .fontSize(12)
          .fontColor(C_SUB)
        Blank()
        Text(`${this.gs.doneEvents.length} 个节点已调查`).fontSize(12).fontColor(C_SUB)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(C_CARD)
    .borderRadius(14)
    .border({ width: 1, color: C_BORDER })
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 18 }) {
          Blank().height(24)

          Text('鸿蒙高级应用开发 · 期末大作业')
            .fontSize(11)
            .fontColor(C_SUB)
            .letterSpacing(2)

          Column({ space: 6 }) {
            Text('回声馆调查事件簿')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(C_TEXT)
            Text('校园线索推理 · 三结局')
              .fontSize(13)
              .fontColor(C_ACCENT)
              .letterSpacing(2)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ top: 4 })

          Divider().color(C_BORDER).width('100%')

          this.briefCard()

          if (this.hasSave) {
            this.progressCard()
          }

          Blank().height(4)

          Button() {
            Text(this.hasSave ? '继续调查' : '接受委托')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(C_ACCENT_DARK)
          }
          .width('100%')
          .height(50)
          .backgroundColor(C_ACCENT)
          .borderRadius(14)
          .onClick(() => {
            this.enterGame();
          })

          if (this.hasSave) {
            Button() {
              Text('重新开始')
                .fontSize(14)
                .fontColor(C_SUB)
            }
            .width('100%')
            .height(44)
            .backgroundColor(Color.Transparent)
            .borderRadius(12)
            .border({ width: 1, color: C_BORDER })
            .onClick(() => {
              this.onStartTap();
            })
          }

          Column({ space: 6 }) {
            Text(`${SCENES.length} 个可探索场景 · 8 条线索 · 3 种结局`)
              .fontSize(11)
              .fontColor(C_SUB)
            Text('GitHub @Nekozhe · 独立完成')
              .fontSize(11)
              .fontColor(C_SUB)
          }
          .margin({ top: 8, bottom: 24 })
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C_BG)
  }
}
