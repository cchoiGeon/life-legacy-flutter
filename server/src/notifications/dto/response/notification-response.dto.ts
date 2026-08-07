import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { NotificationModel } from '../../entities/notification.entity';

export class NotificationResponseDto {
  @ApiProperty() id: string;

  @ApiProperty({
    example: 'daily_question',
    description: 'daily_question | chapter_done | book_ready',
  })
  type: string;

  @ApiProperty({ example: '오늘의 질문이 도착했어요 · 학창 시절과 꿈' })
  title: string;

  @ApiProperty({
    example: '오늘 오전 9:00',
    description:
      '서버가 만든 표시용 문자열 — 앱에서 상대 시각을 계산하지 않는다',
  })
  time_label: string;

  @ApiProperty() is_read: boolean;

  @ApiPropertyOptional({
    nullable: true,
    description: '다권 딥링크 — 어느 책으로 갈지',
  })
  book_id: string | null;

  @ApiPropertyOptional({
    nullable: true,
    description: '작성 화면으로 갈 질문 id (daily_question 등)',
  })
  question_id: string | null;

  @ApiPropertyOptional({
    nullable: true,
    description: '리뷰 화면으로 갈 장 id (chapter_done)',
  })
  chapter_id: string | null;

  static from(
    notification: NotificationModel,
    now: Date,
  ): NotificationResponseDto {
    const linked = notification.linkUserQuestion;
    const chapter = linked?.userChapter ?? null;
    const bookId =
      notification.bookId ??
      chapter?.bookId ??
      chapter?.book?.id ??
      null;

    return {
      id: notification.id,
      type: notification.type,
      title: notification.title,
      time_label: formatTimeLabel(notification.createdAt, now),
      is_read: notification.readAt !== null,
      book_id: bookId,
      question_id: linked?.id ?? null,
      chapter_id: chapter?.id ?? null,
    };
  }
}

/**
 * 기기 시계가 틀어져 있으면 "2시간 전"이 엉뚱하게 나온다. 그래서 서버가
 * 만든다.
 */
function formatTimeLabel(at: Date, now: Date): string {
  const sameDay = at.toDateString() === now.toDateString();
  if (sameDay) {
    const hour = at.getHours();
    const meridiem = hour < 12 ? '오전' : '오후';
    const hour12 = hour % 12 === 0 ? 12 : hour % 12;
    return `오늘 ${meridiem} ${hour12}:${String(at.getMinutes()).padStart(2, '0')}`;
  }

  const days = Math.floor(
    (now.getTime() - at.getTime()) / (24 * 60 * 60 * 1000),
  );
  if (days <= 1) return '어제';
  if (days < 7) return `${days}일 전`;
  if (days < 30) return `${Math.floor(days / 7)}주 전`;
  return `${Math.floor(days / 30)}개월 전`;
}
