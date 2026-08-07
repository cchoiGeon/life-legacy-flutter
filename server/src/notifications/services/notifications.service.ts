import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, IsNull, Repository } from 'typeorm';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { UserQuestionModel } from 'src/chapters/entities/user-question.entity';
import { NotificationResponseDto } from '../dto/response/notification-response.dto';
import { NotificationModel } from '../entities/notification.entity';
import { PushSenderService } from './push-sender.service';

export type CreateNotificationInput = {
  userId: string;
  type: 'daily_question' | 'chapter_done' | 'book_ready';
  title: string;
  bookId?: string | null;
  linkUserQuestionId?: string | null;
  chapterId?: string | null;
  /** true면 인앱 생성 후 FCM도 보낸다 (스케줄러 daily는 직접 보냄) */
  sendPush?: boolean;
};

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(NotificationModel)
    private readonly notifications: Repository<NotificationModel>,
    private readonly pushSender: PushSenderService,
  ) {}

  async list(userId: string): Promise<NotificationResponseDto[]> {
    const rows = await this.notifications.find({
      where: { user: { id: userId } },
      order: { createdAt: 'DESC' },
      relations: {
        linkUserQuestion: { userChapter: true },
      },
    });
    const now = new Date();

    return rows.map((row) => NotificationResponseDto.from(row, now));
  }

  /** 갱신된 목록을 돌려준다 — 앱이 다시 조회하지 않아도 되게 */
  async markAllRead(userId: string): Promise<NotificationResponseDto[]> {
    await this.notifications.update(
      { user: { id: userId }, readAt: IsNull() },
      { readAt: new Date() },
    );

    return await this.list(userId);
  }

  /** 한 건 읽음. 이미 읽었어도 200 — 멱등. */
  async markOneRead(
    userId: string,
    notificationId: string,
  ): Promise<NotificationResponseDto[]> {
    const row = await this.notifications.findOne({
      where: { id: notificationId, user: { id: userId } },
    });
    if (!row) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    if (row.readAt === null) {
      row.readAt = new Date();
      await this.notifications.save(row);
    }

    return await this.list(userId);
  }

  async create(input: CreateNotificationInput): Promise<NotificationModel> {
    const row = await this.notifications.save(
      this.notifications.create({
        user: { id: input.userId } as AppUserModel,
        type: input.type,
        title: input.title,
        bookId: input.bookId ?? null,
        linkUserQuestion: input.linkUserQuestionId
          ? ({ id: input.linkUserQuestionId } as UserQuestionModel)
          : null,
        readAt: null,
      }),
    );

    if (input.sendPush) {
      const data: Record<string, string> = {
        type: input.type,
        notification_id: row.id,
      };
      if (input.bookId) data.book_id = input.bookId;
      if (input.linkUserQuestionId) {
        data.question_id = input.linkUserQuestionId;
      }
      if (input.chapterId) data.chapter_id = input.chapterId;

      await this.pushSender.sendToUser(input.userId, {
        title: row.title,
        data,
      });
    }

    return row;
  }

  async hasDailyQuestionBetween(
    userId: string,
    startUtc: Date,
    endUtc: Date,
  ): Promise<boolean> {
    const count = await this.notifications.count({
      where: {
        user: { id: userId },
        type: 'daily_question',
        createdAt: Between(startUtc, endUtc),
      },
    });
    return count > 0;
  }

  async createChapterDone(input: {
    userId: string;
    bookId: string;
    chapterTitle: string;
    chapterOrder?: number;
    chapterId?: string;
    linkUserQuestionId?: string;
  }): Promise<NotificationModel> {
    const orderLabel =
      input.chapterOrder != null ? `제${input.chapterOrder}장 · ` : '';
    return await this.create({
      userId: input.userId,
      type: 'chapter_done',
      title: `${orderLabel}${input.chapterTitle} 작성을 마쳤어요`,
      bookId: input.bookId,
      linkUserQuestionId: input.linkUserQuestionId ?? null,
      chapterId: input.chapterId ?? null,
      sendPush: true,
    });
  }

  async createBookReady(input: {
    userId: string;
    bookId: string;
    bookTitle?: string;
  }): Promise<NotificationModel> {
    const name = input.bookTitle?.trim() || '자서전';
    return await this.create({
      userId: input.userId,
      type: 'book_ready',
      title: `${name} 초안을 확인할 수 있어요`,
      bookId: input.bookId,
      sendPush: true,
    });
  }

  async createDailyQuestion(input: {
    userId: string;
    bookId: string;
    questionId: string;
    questionText: string;
    sendPush?: boolean;
  }): Promise<NotificationModel> {
    const snippet = input.questionText.trim().slice(0, 40);
    return await this.create({
      userId: input.userId,
      type: 'daily_question',
      title: snippet
        ? `오늘의 질문이 도착했어요 · ${snippet}`
        : '오늘의 질문이 도착했어요',
      bookId: input.bookId,
      linkUserQuestionId: input.questionId,
      sendPush: input.sendPush ?? false,
    });
  }
}
