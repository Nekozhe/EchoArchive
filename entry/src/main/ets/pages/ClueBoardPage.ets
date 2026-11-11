/**
 * 线索板页
 * 职责：展示已获得线索与未解锁线索、查看线索详情、跳转推理台
 */
import { router } from '@kit.ArkUI';
import { Clue, CLUE_TOTAL, GameState, newGameState, UNLOCK_BOARD_CLUES } from '../model/GameTypes';
import { canOpenBoard } from '../logic/GameLogic';
import { CLUES } from '../data/CaseData';
import { SaveService } from '../service/SaveService';
import { C_ACCENT, C_ACCENT_DARK, C_BG, C_BORDER, C_CARD, C_OK, C_SUB, C_TEXT } from '../common/Theme';

@Entry
@Component
struct ClueBoardPage {
  @State gs: GameState = newGameState();
  @State selName: string = '';
  @State selDesc: string = '';
  @State selKey: boolean = false;
  @State showDetail: boolean = false;

  aboutToAppear(): void {
    SaveService.load().then((state: GameState) => {
      this.gs = state;
    });
  }

  onPageShow(): void {
    SaveService.load().then((state: GameState) => {
      this.gs = state;
    });
  }

  private ownedCount(): number {
    return this.gs.ownedClues.length;
  }

  private isOwned(clue: Clue): boolean {
    return this.gs.ownedClues.indexOf(clue.id) >= 0;
  }

  @Builder
  clueCard(clue: Clue) {
    Column({ space: 6 }) {
      Row() {
        Text(this.isOwned(clue) ? clue.name : '未解锁')
          .fontSize(14)
          .fontColor(this.isOwned(clue) ? C_TEXT : C_SUB)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        if (this.isOwned(clue) && clue.keyClue) {
          Text('关键')
            .fontSize(9)
            .fontColor(C_ACCENT_DARK)
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .backgroundColor(C_ACCENT)
            .borderRadius(4)
        }
      }
      .width('100%')

      Text(this.isOwned(clue) ? clue.id : '· · ·')
        .fontSize(10)
        .fontColor(C_SUB)

      Text(this.isOwned(clue) ? clue.desc : '继续调查以解锁')
        .fontSize(11)
        .fontColor(this.isOwned(clue) ? C_SUB : '#4C5A6E')
        .lineHeight(16)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .width('100%')
    .height(112)
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .backgroundColor(C_CARD)
    .borderRadius(14)
    .border({ width: 1, color: this.isOwned(clue) ? C_BORDER : '#222B38' })
    .opacity(this.isOwned(clue) ? 1 : 0.6)
    .onClick(() => {
      if (!this.isOwned(clue)) {
        return;
      }
      this.selName = clue.name;
      this.selDesc = clue.desc;
      this.selKey = clue.keyClue;
      this.showDetail = true;
    })
  }

  @Builder
  detailLayer() {
    Column() {
      Blank()
      Column({ space: 12 }) {
        Row() {
          Text(this.selName).fontSize(17).fontColor(C_TEXT).fontWeight(FontWeight.Medium)
          Blank()
          if (this.selKey) {
            Text('关键线索')
              .fontSize(10)
              .fontColor(C_ACCENT)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .border({ width: 1, color: C_ACCENT })
              .borderRadius(5)
          }
        }
        .width('100%')

        Text(this.selDesc)
          .fontSize(14)
          .fontColor(C_SUB)
          .lineHeight(24)
          .width('100%')

        Button() {
          Text('收起').fontSize(13).fontColor(C_ACCENT_DARK)
        }
        .width('100%')
        .height(42)
        .backgroundColor(C_ACCENT)
        .borderRadius(10)
        .margin({ top: 6 })
        .onClick(() => {
          this.showDetail = false;
        })
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
      this.showDetail = false;
    })
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('‹').fontSize(26).fontColor(C_TEXT).width(30).onClick(() => {
            router.back();
          })
          Column({ space: 2 }) {
            Text('线索板').fontSize(15).fontColor(C_TEXT)
            Text('关键线索可用于推理台').fontSize(10).fontColor(C_SUB)
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Text(`${this.ownedCount()} / ${CLUE_TOTAL}`).fontSize(14).fontColor(C_ACCENT)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })

        Scroll() {
          Column({ space: 14 }) {
            Grid() {
              ForEach(CLUES, (clue: Clue) => {
                GridItem() {
                  this.clueCard(clue)
                }
              }, (clue: Clue) => clue.id)
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .width('100%')

            Row() {
              Text('柜子里的档案').fontSize(11).fontColor(C_SUB).letterSpacing(1)
              Blank()
              Text(`${this.gs.doneEvents.length} 个节点已调查`).fontSize(11).fontColor(C_SUB)
            }
            .width('100%')
            .margin({ top: 4 })

            Blank().height(16)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 8 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)

        Button() {
          Text(canOpenBoard(this.gs, UNLOCK_BOARD_CLUES) ? '去推理台' : `再收集 ${UNLOCK_BOARD_CLUES - this.ownedCount()} 条线索解锁推理`)
            .fontSize(14)
            .fontColor(canOpenBoard(this.gs, UNLOCK_BOARD_CLUES) ? C_ACCENT_DARK : C_SUB)
        }
        .width('100%')
        .height(46)
        .margin({ left: 20, right: 20, bottom: 18 })
        .backgroundColor(canOpenBoard(this.gs, UNLOCK_BOARD_CLUES) ? C_ACCENT : C_CARD)
        .borderRadius(12)
        .border({ width: 1, color: C_BORDER })
        .onClick(() => {
          if (canOpenBoard(this.gs, UNLOCK_BOARD_CLUES)) {
            router.pushUrl({ url: 'pages/DeductionPage' });
          }
        })
      }
      .width('100%')
      .height('100%')

      if (this.showDetail) {
        this.detailLayer()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C_BG)
  }
}
