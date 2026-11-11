/**
 * 结局页
 * 职责：展示结局文案、复盘本案线索与提交次数、重新开始
 */
import { router } from '@kit.ArkUI';
import { Clue, EndingDef, GameState, newGameState } from '../model/GameTypes';
import { CLUES, ENDINGS, findEnding } from '../data/CaseData';
import { SaveService } from '../service/SaveService';
import { C_ACCENT, C_ACCENT_DARK, C_BG, C_BORDER, C_CARD, C_SUB, C_TEXT } from '../common/Theme';

interface EndingParams {
  endingId: string;
}

@Entry
@Component
struct EndingPage {
  @State gs: GameState = newGameState();
  @State endingId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as EndingParams;
    if (params !== undefined && params !== null && params.endingId !== undefined) {
      this.endingId = params.endingId;
    }
    SaveService.load().then((state: GameState) => {
      this.gs = state;
      if (this.endingId === '' && state.endingId !== '') {
        this.endingId = state.endingId;
      }
    });
  }

  private currentEnding(): EndingDef | undefined {
    return findEnding(this.endingId);
  }

  private ownedClueList(): Clue[] {
    return CLUES.filter((item: Clue) => this.gs.ownedClues.indexOf(item.id) >= 0);
  }

  private restart(): void {
    SaveService.clear().then(() => {
      this.gs = newGameState();
      router.replaceUrl({ url: 'pages/Index' });
    });
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          Blank().height(28)

          Text('调查结束')
            .fontSize(11)
            .fontColor(C_SUB)
            .letterSpacing(3)
            .width('100%')

          Text(this.currentEnding() === undefined ? '结局' : this.currentEnding()!.title)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(C_ACCENT)
            .width('100%')

          Divider().color(C_BORDER).width('100%')

          Text(this.currentEnding() === undefined ? '' : this.currentEnding()!.text)
            .fontSize(15)
            .fontColor(C_TEXT)
            .lineHeight(28)
            .width('100%')

          Column({ space: 10 }) {
            Row() {
              Text('复盘').fontSize(13).fontColor(C_TEXT)
              Blank()
              Text(`${this.gs.ownedClues.length} 条线索 · ${this.gs.attemptCount} 次指认`)
                .fontSize(11)
                .fontColor(C_SUB)
            }
            .width('100%')

            Divider().color(C_BORDER).width('100%')

            ForEach(this.ownedClueList(), (clue: Clue) => {
              Row({ space: 8 }) {
                Text(clue.keyClue ? '★' : '·')
                  .fontSize(11)
                  .fontColor(clue.keyClue ? C_ACCENT : C_SUB)
                Text(clue.name).fontSize(13).fontColor(C_TEXT).layoutWeight(1)
                Text(clue.id).fontSize(10).fontColor(C_SUB)
              }
              .width('100%')
            }, (clue: Clue) => clue.id)

            Text(this.gs.ownedClues.length < CLUES.length
              ? `还有 ${CLUES.length - this.gs.ownedClues.length} 条线索这局没找到。`
              : '这一局你翻遍了所有角落。')
              .fontSize(11)
              .fontColor(C_SUB)
              .width('100%')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding(18)
          .backgroundColor(C_CARD)
          .borderRadius(16)
          .border({ width: 1, color: C_BORDER })
          .alignItems(HorizontalAlign.Start)

          Row({ space: 12 }) {
            Button() {
              Text('重新调查').fontSize(14).fontColor(C_ACCENT_DARK)
            }
            .layoutWeight(1)
            .height(46)
            .backgroundColor(C_ACCENT)
            .borderRadius(12)
            .onClick(() => {
              this.restart();
            })

            Button() {
              Text('看线索板').fontSize(14).fontColor(C_TEXT)
            }
            .layoutWeight(1)
            .height(46)
            .backgroundColor(C_CARD)
            .borderRadius(12)
            .border({ width: 1, color: C_BORDER })
            .onClick(() => {
              router.pushUrl({ url: 'pages/ClueBoardPage' });
            })
          }
          .width('100%')
          .margin({ top: 4 })

          Text(`本案共 ${ENDINGS.length} 种结局，换一组推理条件可以走到别的分支。`)
            .fontSize(11)
            .fontColor(C_SUB)
            .width('100%')
            .margin({ bottom: 24 })
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C_BG)
  }
}
