import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { BookAccessService } from 'src/book/services/book-access.service';
import { ChaptersService } from 'src/chapters/services/chapters.service';
import { WritingPlanModel } from 'src/intro/entities/writing-plan.entity';
import { UserSettingModel } from 'src/users/entities/user-setting.entity';
import { NotificationsService } from './notifications.service';
import { PushSenderService } from './push-sender.service';

/** Asia/Seoul 오전 슬롯 — 작성 가능 `am`을 알림 시각으로 매핑 */
export const PUSH_SLOT_AM_HOUR = 9;
/** Asia/Seoul 오후 슬롯 — 작성 가능 `pm`을 알림 시각으로 매핑 */
export const PUSH_SLOT_PM_HOUR = 14;

const TIME_ZONE = 'Asia/Seoul';

/** writing_plan이 없을 때 기본: 월–금 오전 */
const DEFAULT_WEEKDAYS = [1, 2, 3, 4, 5];
const DEFAULT_PERIODS = ['am'];

export type SeoulParts = {
  year: number;
  month: number;
  day: number;
  hour: number;
  weekday: number; // 0=일 … 6=토 (Date.getDay와 동일)
};

/**
 * 오늘의 질문 푸시 스케줄러.
 *
 * Cron: 매일 09:05 · 14:05 (Asia/Seoul).
 * - user_setting.daily_question_alarm === true (행 없으면 true)
 * - writing_plan.available_weekdays / available_periods (없으면 월–금 am)
 * - writing_plan.alarm_enabled === true (계획 행이 있을 때만)
 * - 당일 이미 daily_question 인앱 알림이 있으면 스킵
 */
@Injectable()
export class DailyQuestionSchedulerService {
  private readonly logger = new Logger(DailyQuestionSchedulerService.name);

  constructor(
    @InjectRepository(UserSettingModel)
    private readonly settings: Repository<UserSettingModel>,
    @InjectRepository(WritingPlanModel)
    private readonly plans: Repository<WritingPlanModel>,
    private readonly bookAccess: BookAccessService,
    private readonly chapters: ChaptersService,
    private readonly notifications: NotificationsService,
    private readonly pushSender: PushSenderService,
  ) {}

  @Cron('5 9,14 * * *', { timeZone: TIME_ZONE })
  async runScheduledSlots(): Promise<void> {
    const seoul = seoulNowParts(new Date());
    const period = periodForHour(seoul.hour);
    if (!period) {
      this.logger.debug(`Skip cron at hour=${seoul.hour} (not a push slot)`);
      return;
    }

    await this.dispatchForPeriod(period, seoul);
  }

  /** 테스트·수동 트리거용 */
  async dispatchForPeriod(
    period: 'am' | 'pm',
    seoul: SeoulParts = seoulNowParts(new Date()),
  ): Promise<{ sent: number; skipped: number }> {
    let sent = 0;
    let skipped = 0;

    const plans = await this.plans.find();
    const planByUser = new Map(plans.map((p) => [p.userId, p]));

    const settingRows = await this.settings.find();
    const alarmByUser = new Map(
      settingRows.map((s) => [s.userId, s.dailyQuestionAlarm]),
    );

    const candidateIds = new Set<string>([
      ...planByUser.keys(),
      ...alarmByUser.keys(),
    ]);

    const owners = await this.bookAccess.findAllOwnerUserIds();
    for (const id of owners) candidateIds.add(id);

    for (const userId of candidateIds) {
      const alarmOn = alarmByUser.get(userId) ?? true;
      if (!alarmOn) {
        skipped += 1;
        continue;
      }

      const plan = planByUser.get(userId);
      if (plan && plan.alarmEnabled === false) {
        skipped += 1;
        continue;
      }

      const weekdays = plan?.availableWeekdays?.length
        ? plan.availableWeekdays
        : DEFAULT_WEEKDAYS;
      const periods = plan?.availablePeriods?.length
        ? plan.availablePeriods.map((p) => p.toLowerCase())
        : DEFAULT_PERIODS;

      if (!weekdays.includes(seoul.weekday) || !periods.includes(period)) {
        skipped += 1;
        continue;
      }

      const ok = await this.trySendDailyQuestion(userId, seoul, period);
      if (ok) sent += 1;
      else skipped += 1;
    }

    this.logger.log(
      `daily_question slot=${period} seoul=${seoul.year}-${seoul.month}-${seoul.day} sent=${sent} skipped=${skipped}`,
    );
    return { sent, skipped };
  }

  private async trySendDailyQuestion(
    userId: string,
    seoul: SeoulParts,
    period: 'am' | 'pm',
  ): Promise<boolean> {
    const books = await this.bookAccess.findOwnedBooks(userId);
    if (books.length === 0) return false;

    const book = books[0];
    const question = await this.chapters.getCurrentQuestion(userId, book.id);
    if (!question) return false;

    const { startUtc, endUtc } = seoulSlotUtcRange(seoul, period);
    const already = await this.notifications.hasDailyQuestionBetween(
      userId,
      startUtc,
      endUtc,
    );
    if (already) return false;

    const row = await this.notifications.createDailyQuestion({
      userId,
      bookId: book.id,
      questionId: question.id,
      questionText: question.text,
    });

    await this.pushSender.sendToUser(userId, {
      title: row.title,
      body: '오늘의 질문에 답해 보세요',
      data: {
        type: 'daily_question',
        notification_id: row.id,
        book_id: book.id,
        question_id: question.id,
      },
    });

    return true;
  }
}

export function periodForHour(hour: number): 'am' | 'pm' | null {
  if (hour === PUSH_SLOT_AM_HOUR) return 'am';
  if (hour === PUSH_SLOT_PM_HOUR) return 'pm';
  return null;
}

export function seoulNowParts(now: Date): SeoulParts {
  const fmt = new Intl.DateTimeFormat('en-US', {
    timeZone: TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    hour12: false,
    weekday: 'short',
  });
  const parts = Object.fromEntries(
    fmt.formatToParts(now).map((p) => [p.type, p.value]),
  ) as Record<string, string>;

  const weekdayMap: Record<string, number> = {
    Sun: 0,
    Mon: 1,
    Tue: 2,
    Wed: 3,
    Thu: 4,
    Fri: 5,
    Sat: 6,
  };

  // hour12:false 에서 자정은 "24"로 나오는 런타임이 있다.
  let hour = Number(parts.hour);
  if (hour === 24) hour = 0;

  return {
    year: Number(parts.year),
    month: Number(parts.month),
    day: Number(parts.day),
    hour,
    weekday: weekdayMap[parts.weekday] ?? 0,
  };
}

/** 서울 달력일 00:00~다음날 00:00 을 UTC Date로 */
export function seoulDayUtcRange(seoul: SeoulParts): {
  startUtc: Date;
  endUtc: Date;
} {
  // Asia/Seoul = UTC+9 (DST 없음)
  const startUtc = new Date(
    Date.UTC(seoul.year, seoul.month - 1, seoul.day, 0, 0, 0) -
      9 * 60 * 60 * 1000,
  );
  const endUtc = new Date(startUtc.getTime() + 24 * 60 * 60 * 1000);
  return { startUtc, endUtc };
}

/** 슬롯 시각 ±30분 창 — am/pm 각각 하루 1회 */
export function seoulSlotUtcRange(
  seoul: SeoulParts,
  period: 'am' | 'pm',
): { startUtc: Date; endUtc: Date } {
  const hour = period === 'am' ? PUSH_SLOT_AM_HOUR : PUSH_SLOT_PM_HOUR;
  const startUtc = new Date(
    Date.UTC(seoul.year, seoul.month - 1, seoul.day, hour, 0, 0) -
      9 * 60 * 60 * 1000,
  );
  const endUtc = new Date(startUtc.getTime() + 60 * 60 * 1000);
  return { startUtc, endUtc };
}
