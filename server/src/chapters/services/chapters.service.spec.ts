import { ChapterStatus } from '../const/chapter-status.enum';
import { QuestionStatus } from '../const/question-status.enum';
import { ChaptersService } from './chapters.service';

/**
 * 장 순차 잠금과 소유권 — 남의 자서전을 들여다볼 수 있는지가 걸린 자리다.
 */
function buildService() {
  const chaptersRepository = {
    findAllByBook: jest.fn(),
    findWritingChapter: jest.fn(),
    findFirstPending: jest.fn(),
    findQuestionById: jest.fn(),
    findChapterById: jest.fn(),
    findNextChapter: jest.fn(),
    countQuestionsInChapter: jest.fn(),
    saveQuestion: jest
      .fn()
      .mockImplementation((q: unknown) => Promise.resolve(q)),
  };
  const bookAccess = {
    requireOwnedBook: jest.fn().mockResolvedValue({ id: 'b1' }),
  };
  const reviews = {
    findOne: jest.fn().mockResolvedValue(null),
    find: jest.fn().mockResolvedValue([]),
  };

  return {
    service: new ChaptersService(
      chaptersRepository as never,
      bookAccess as never,
      reviews as never,
    ),
    chaptersRepository,
    reviews,
  };
}

const question = (overrides: Record<string, unknown> = {}) => ({
  id: 'q1',
  sortOrder: 1,
  text: '어릴 적 동네는 어땠나요?',
  status: QuestionStatus.PENDING,
  isEdited: false,
  userChapter: {
    id: 'c1',
    bookId: 'b1',
    status: ChapterStatus.WRITING,
    book: { id: 'b1', ownerUserId: 'u1' },
  },
  ...overrides,
});

describe('ChaptersService · 소유권과 잠금', () => {
  it('남의 질문은 404다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findQuestionById.mockResolvedValue(
      question({
        userChapter: {
          id: 'c1',
          bookId: 'b1',
          status: ChapterStatus.WRITING,
          book: { id: 'b1', ownerUserId: 'other' },
        },
      }),
    );

    await expect(service.getOwnedQuestion('u1', 'q1')).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'NOT_FOUND' }),
    });
  });

  it('잠긴 장 질문은 CHAPTER_LOCKED다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findQuestionById.mockResolvedValue(
      question({
        userChapter: {
          id: 'c1',
          bookId: 'b1',
          status: ChapterStatus.LOCKED,
          book: { id: 'b1', ownerUserId: 'u1' },
        },
      }),
    );

    await expect(service.getOwnedQuestion('u1', 'q1')).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'CHAPTER_LOCKED' }),
    });
  });

  it('장 목록은 책 범위로 조회하고 review_status를 실는다', async () => {
    const { service, chaptersRepository, reviews } = buildService();
    chaptersRepository.findAllByBook.mockResolvedValue([
      {
        id: 'c1',
        sortOrder: 1,
        title: '탄생',
        status: ChapterStatus.DONE,
        answeredCount: 5,
        questionCount: 5,
        sourceType: 'template',
      },
    ]);
    reviews.find.mockResolvedValue([
      { userChapterId: 'c1', status: 'reviewed' },
    ]);

    const items = await service.getChapters('u1', 'b1');
    expect(chaptersRepository.findAllByBook).toHaveBeenCalledWith('b1');
    expect(items[0].review_status).toBe('reviewed');
    expect(items[0].ebook_eligible).toBe(true);
  });

  it('장 목록 writing 장은 next_question_text를 채운다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findAllByBook.mockResolvedValue([
      {
        id: 'c1',
        sortOrder: 1,
        title: '탄생',
        status: ChapterStatus.WRITING,
        answeredCount: 0,
        questionCount: 5,
        sourceType: 'template',
      },
    ]);
    chaptersRepository.findFirstPending.mockResolvedValue({
      text: '다음 질문',
    });

    const items = await service.getChapters('u1', 'b1');
    expect(items[0].next_question_text).toBe('다음 질문');
    expect(items[0].review_status).toBeNull();
  });

  it('현재 질문이 없으면 null', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findWritingChapter.mockResolvedValue(null);

    await expect(service.getCurrentQuestion('u1', 'b1')).resolves.toBeNull();
  });
});

describe('ChaptersService · 챕터 완료', () => {
  it('done 장이면 review CTA를 켠다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findChapterById.mockResolvedValue({
      id: 'c2',
      bookId: 'b1',
      sortOrder: 2,
      title: '가족',
      status: ChapterStatus.DONE,
    });
    chaptersRepository.countQuestionsInChapter.mockResolvedValue({
      questionCount: 6,
      answeredCount: 5,
      skippedCount: 1,
    });
    chaptersRepository.findNextChapter.mockResolvedValue({
      id: 'c3',
      sortOrder: 3,
      title: '청소년기',
    });

    const result = await service.getChapterCompletion('u1', 'b1', 'c2');

    expect(result).toMatchObject({
      chapter_id: 'c2',
      chapter_order: 2,
      answered_count: 5,
      skipped_count: 1,
      review_status: null,
      actions: { review: true, hub: true },
      next_chapter: { id: 'c3', order: 3, title: '청소년기' },
    });
  });

  it('잠긴 장은 CHAPTER_LOCKED', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findChapterById.mockResolvedValue({
      id: 'c3',
      bookId: 'b1',
      sortOrder: 3,
      title: '잠김',
      status: ChapterStatus.LOCKED,
    });

    await expect(
      service.getChapterCompletion('u1', 'b1', 'c3'),
    ).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'CHAPTER_LOCKED' }),
    });
  });
});
