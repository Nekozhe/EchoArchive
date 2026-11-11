/**
 * 推理台页
 * 职责：选择人物 / 时段 / 物证，提交后由 judgeDeduction 判定并跳转结局
 */
import { router, promptAction } from '@kit.ArkUI';
import {
  CLUE_TOTAL, DeductionSlots, GameState, JudgeResult, newGameState, OptionItem
} from '../model/GameTypes';
import { judgeDeduction } from '../logic/GameLogic';
import { EVIDENCE_OPTIONS, PERSON_OPTIONS, PERIOD_OPTIONS } from '../data/CaseData';
import { SaveService } from '../service/SaveService';
import { C_ACCENT, C_ACCENT_DARK, C_BG, C_BORDER, C_CARD, C_CARD_LIGHT, C_SUB, C_TEXT } from '../common/Theme';

interface EndingParams {
  endingId: string;
}

@Entry
@Component
struct DeductionPage {
  @State gs: GameState = newGameState();
  @State person: string = '';
  @State period: string = '';
  @State evidence: string = '';
  @State submitting: boolean = false;

  aboutToAppear(): void {
    SaveService.load().then((state: GameState) => {
      this.gs = state;
    });
  }

  private optionsOf(personMode: boolean): OptionItem[] {
    return personMode ? PERSON_OPTIONS : PERIOD_OPTIONS;
  }

  private isEvidenceUnlocked(item: OptionItem): boolean {
    return this.gs.ownedClues.indexOf(item.id) >= 0;
  }

  private summaryText(): string {
    const p: string = this.person === '' ? '未选' : this.person;
    const t: string = this.period === '' ? '未选' : this.period;
    const e: string = this.evidence === '' ? '未选' : this.evidence;
    return `${p} / ${t} / ${e}`;
  }

  private submit(): void {
    if (this.submitting) {
      return;
    }
    this.submitting = true;
    const slots: DeductionSlots = {
      person: this.person,
      period: this.period,
      evidence: this.evidence
    };
    const result: JudgeResult = judgeDeduction(this.gs, slots);
    if (!result.ok) {
      this.submitting = false;
      promptAction.showToast({ message: result.reason });
      return;
    }
    this.gs.attemptCount = this.gs.attemptCount + 1;
    this.gs.endingId = result.endingId;
    SaveService.save(this.gs).then(() => {
      const params: EndingParams = { endingId: result.endingId };
      router.replaceUrl({ url: 'pages/EndingPage', params: params });
      this.submitting = false;
    });
  }

  @Builder
  chipRow(title: string, options: OptionItem[], current: string, kind: string) {
    Column({ space: 10 }) {
      Row() {
        Text(title).fontSize(13).fontColor(C_TEXT)
        Blank()
        Text(kind === 'evidence' ? '仅显示已获得' : '').fontSize(10).fontColor(C_SUB)
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(options, (item: OptionItem) => {
          Text(item.label)
            .fontSize(13)
            .fontColor(this.isLocked(item, kind) ? '#4C5A6E'
              : (current === item.id ? C_ACCENT_DARK : C_TEXT))
            .padding({ left: 14, right: 14, top: 9, bottom: 9 })
            .margin({ right: 8, bottom: 8 })
            .backgroundColor(this.isLocked(item, kind) ? '#1B2330'
              : (current === item.id ? C_ACCENT : C_CARD_LIGHT))
            .borderRadius(9)
            .border({ width: 1, color: current === item.id ? C_ACCENT : C_BORDER })
            .onClick(() => {
              if (this.isLocked(item, kind)) {
                promptAction.showToast({ message: '这条物证还没拿到' });
                return;
              }
              if (kind === 'person') {
                this.person = item.id;
              } else if (kind === 'period') {
                this.period = item.id;
              } else {
                this.evidence = item.id;
              }
            })
        }, (item: OptionItem) => item.id)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(C_CARD)
    .borderRadius(14)
    .border({ width: 1, color: C_BORDER })
    .alignItems(HorizontalAlign.Start)
  }

  private isLocked(item: OptionItem, kind: string): boolean {
    if (kind !== 'evidence') {
      return false;
    }
    return !this.isEvidenceUnlocked(item);
  }

  build() {
    Column() {
      Row() {
        Text('‹').fontSize(26).fontColor(C_TEXT).width(30).onClick(() => {
          router.back();
        })
        Column({ space: 2 }) {
          Text('推理台').fontSize(15).fontColor(C_TEXT)
          Text('把线索排成一条能站住的链').fontSize(10).fontColor(C_SUB)
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

      Scroll() {
        Column({ space: 12 }) {
          Text('你的假设')
            .fontSize(11)
            .fontColor(C_SUB)
            .letterSpacing(2)
            .width('100%')
            .margin({ top: 8 })

          Text(this.summaryText())
            .fontSize(14)
            .fontColor(C_ACCENT)
            .width('100%')
            .padding(14)
            .backgroundColor('#1B2432')
            .borderRadius(10)

          this.chipRow('谁搬走了原型机', PERSON_OPTIONS, this.person, 'person')
          this.chipRow('发生在这段时间', PERIOD_OPTIONS, this.period, 'period')
          this.chipRow('用哪条物证支撑', EVIDENCE_OPTIONS, this.evidence, 'evidence')

          Text(`已提交 ${this.gs.attemptCount} 次。指认错误会直接进入对应结局，无法反悔。`)
            .fontSize(11)
            .fontColor(C_SUB)
            .lineHeight(18)
            .width('100%')
            .margin({ top: 2 })

          Blank().height(12)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)

      Button() {
        Text(this.submitting ? '提交中…' : '提交指认')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(C_ACCENT_DARK)
      }
      .width('100%')
      .height(48)
      .margin({ left: 20, right: 20, bottom: 18 })
      .backgroundColor(this.person !== '' && this.period !== '' && this.evidence !== '' ? C_ACCENT : '#3B4557')
      .borderRadius(12)
      .onClick(() => {
        this.submit();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(C_BG)
  }
}
