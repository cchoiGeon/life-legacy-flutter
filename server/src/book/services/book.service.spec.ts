import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { ReviewStatus } from 'src/common/const/review-status.enum';
import { BookService } from './book.service';

/**
 * 쪽 나누기는 **서버가** 한다. 앱은 받은 대로 그린다.
 */
function buildService(
  options: {
    chapters?: unknown[];
    answersByChapter?: Record<string, unknown[]>;
    reviews?: Array<{ userChapterId: string; status: ReviewStatus }>;
  } = {},
) {
  const pages = {};
  const books = {};
  const reviews = {
    find: jest.fn().mockResolvedValue(options.reviews ?? []),
  };
  const bookAccess = {
    requireOwnedBook: jest.fn().mockResolvedValue({
      id: 'b1',
      title: '나의 이야기',
      authorName: '김영희',
      photoCount: 0,
    }),
    findOwnedBooks: jest.fn().mockResolvedValue([]),
  };
  const chaptersRepository = {
    findAllByBook: jest.fn().mockResolvedValue(options.chapters ?? []),
    countByBook: jest.fn().mockResolvedValue({ total: 0, answered: 0 }),
    findWritingChapter: jest.fn().mockResolvedValue(null),
    findFirstPending: jest.fn().mockResolvedValue(null),
  };
  const answersRepository = {
    findPolishedByChapter: jest
      .fn()
      .mockImplementation((id: string) =>
        Promise.resolve(options.answersByChapter?.[id] ?? []),
      ),
    countAnsweredByBook: jest.fn().mockResolvedValue(0),
  };
  const entitlementService = {
    getDashboardEntitlements: jest.fn().mockResolvedValue({
      ebook: { allowed: true, reason: null },
      audiobook: { allowed: false, reason: 'PLAN_REQUIRED' },
      storybook: { allowed: false, reason: 'WEB_ONLY' },
    }),
    getBookEntitlements: jest.fn().mockResolvedValue({
      plan_code: 'free',
      features: {},
    }),
  };

  return {
    service: new BookService(
      pages as never,
      books as never,
      reviews as never,
      bookAccess as never,
      chaptersRepository as never,
      answersRepository as never,
      entitlementService as never,
    ),
    answersRepository,
    entitlementService,
  };
}

const chapter = (id: string, order: number, status: ChapterStatus) => ({
  id,
  sortOrder: order,
  title: `${order}장`,
  status,
  answeredCount: 0,
  questionCount: 5,
});

describe('BookService · 미리보기 쪽', () => {
  it('reviewed 장만 싣는다', async () => {
    const { service, answersRepository } = buildService({
      chapters: [
        chapter('c1', 1, ChapterStatus.DONE),
        chapter('c2', 2, ChapterStatus.DONE),
        chapter('c3', 3, ChapterStatus.WRITING),
      ],
      reviews: [{ userChapterId: 'c1', status: ReviewStatus.REVIEWED }],
      answersByChapter: {
        c1: [{ polishedText: '첫 문단\n\n둘째 문단', firstText: '원문' }],
        c2: [{ polishedText: '리뷰 전', firstText: '원문' }],
      },
    });

    const pages = await service.getPages('u1', 'b1');

    expect(answersRepository.findPolishedByChapter).toHaveBeenCalledWith('c1');
    expect(answersRepository.findPolishedByChapter).not.toHaveBeenCalledWith(
      'c2',
    );
    expect(pages.length).toBeGreaterThan(0);
  });

  it('문단 3개씩 쪽으로 나눈다', async () => {
    const { service } = buildService({
      chapters: [chapter('c1', 1, ChapterStatus.DONE)],
      reviews: [{ userChapterId: 'c1', status: ReviewStatus.REVIEWED }],
      answersByChapter: {
        c1: [
          {
            polishedText: 'a\n\nb\n\nc\n\nd',
            firstText: '',
          },
        ],
      },
    });

    const pages = await service.getPages('u1', 'b1');
    expect(pages).toHaveLength(2);
    expect(pages[0].paragraphs).toEqual(['a', 'b', 'c']);
    expect(pages[1].paragraphs).toEqual(['d']);
    expect(pages.every((p) => p.total_pages === 2)).toBe(true);
  });
});

describe('BookService · entitlements', () => {
  it('소유 책의 상세 entitlements를 위임한다', async () => {
    const { service, entitlementService } = buildService({
      chapters: [chapter('c1', 1, ChapterStatus.WRITING)],
    });

    await service.getBook('u1', 'b1');
    expect(entitlementService.getDashboardEntitlements).toHaveBeenCalledWith(
      'u1',
      'b1',
    );
  });

  it('GET entitlements는 소유 검사 후 §11 응답을 돌린다', async () => {
    const { service, entitlementService } = buildService();
    entitlementService.getBookEntitlements.mockResolvedValue({
      plan_code: 'free',
      features: {
        ebook: { allowed: true, reason: null, remaining_generations: null },
      },
    });

    const result = await service.getEntitlements('u1', 'b1');
    expect(result.plan_code).toBe('free');
    expect(entitlementService.getBookEntitlements).toHaveBeenCalledWith(
      'u1',
      'b1',
    );
  });
});
