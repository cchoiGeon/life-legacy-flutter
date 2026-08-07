import { NotificationResponseDto } from './notification-response.dto';

/**
 * time_label은 **서버가** 만든다. 기기 시계가 틀어져 있으면 "2시간 전"이
 * 엉뚱하게 나오기 때문이다. 그래서 이 포맷이 곧 계약이다.
 */
function notification(
  createdAt: Date,
  readAt: Date | null = null,
  extras: {
    type?: string;
    bookId?: string | null;
    questionId?: string;
    chapterId?: string;
    chapterBookId?: string;
  } = {},
) {
  return {
    id: 'n1',
    type: extras.type ?? 'daily_question',
    title: '오늘의 질문이 도착했어요',
    createdAt,
    readAt,
    bookId: extras.bookId ?? null,
    linkUserQuestion:
      extras.questionId || extras.chapterId
        ? {
            id: extras.questionId ?? 'q1',
            userChapter: {
              id: extras.chapterId ?? 'c1',
              bookId: extras.chapterBookId ?? extras.bookId ?? 'b1',
            },
          }
        : null,
  } as never;
}

describe('NotificationResponseDto.from · time_label', () => {
  const now = new Date('2026-07-31T15:00:00');

  it('오늘이면 시각을 오전/오후로 적는다', () => {
    const dto = NotificationResponseDto.from(
      notification(new Date('2026-07-31T09:05:00')),
      now,
    );

    expect(dto.time_label).toBe('오늘 오전 9:05');
  });

  it('정오는 오후 12시다', () => {
    const dto = NotificationResponseDto.from(
      notification(new Date('2026-07-31T12:30:00')),
      now,
    );

    expect(dto.time_label).toBe('오늘 오후 12:30');
  });

  it('자정은 오전 12시다', () => {
    const dto = NotificationResponseDto.from(
      notification(new Date('2026-07-31T00:10:00')),
      now,
    );

    expect(dto.time_label).toBe('오늘 오전 12:10');
  });

  it.each([
    ['어제', new Date('2026-07-30T09:00:00'), '어제'],
    ['3일 전', new Date('2026-07-28T09:00:00'), '3일 전'],
    ['2주 전', new Date('2026-07-16T09:00:00'), '2주 전'],
    ['1개월 전', new Date('2026-06-20T09:00:00'), '1개월 전'],
  ])('%s', (_label, at, expected) => {
    expect(NotificationResponseDto.from(notification(at), now).time_label).toBe(
      expected,
    );
  });

  it('읽음 여부는 readAt으로 가른다', () => {
    expect(
      NotificationResponseDto.from(notification(now, null), now).is_read,
    ).toBe(false);
    expect(
      NotificationResponseDto.from(notification(now, now), now).is_read,
    ).toBe(true);
  });

  it('딥링크 id를 type·관계에서 채운다', () => {
    const dto = NotificationResponseDto.from(
      notification(now, null, {
        type: 'chapter_done',
        bookId: 'b9',
        questionId: 'q9',
        chapterId: 'c9',
      }),
      now,
    );

    expect(dto.type).toBe('chapter_done');
    expect(dto.book_id).toBe('b9');
    expect(dto.question_id).toBe('q9');
    expect(dto.chapter_id).toBe('c9');
  });

  it('book_id가 없으면 연결 질문의 장에서 보완한다', () => {
    const dto = NotificationResponseDto.from(
      notification(now, null, {
        bookId: null,
        questionId: 'q2',
        chapterId: 'c2',
        chapterBookId: 'b2',
      }),
      now,
    );

    expect(dto.book_id).toBe('b2');
  });
});
