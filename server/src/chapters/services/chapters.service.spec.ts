import { ChapterStatus } from '../const/chapter-status.enum';
import { QuestionStatus } from '../const/question-status.enum';
import { ChaptersService } from './chapters.service';

/**
 * 장 순차 잠금과 소유권 — 남의 자서전을 들여다볼 수 있는지가 걸린 자리다.
 */
function buildService() {
  const chaptersRepository = {
    findAllByUser: jest.fn(),
    findWritingChapter: jest.fn(),
    findFirstPending: jest.fn(),
    findQuestionById: jest.fn(),
    saveQuestion: jest
      .fn()
      .mockImplementation((q: unknown) => Promise.resolve(q)),
  };

  return {
    service: new ChaptersService(chaptersRepository as never),
    chaptersRepository,
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
    status: ChapterStatus.WRITING,
    user: { id: 'u1' },
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
          status: ChapterStatus.WRITING,
          user: { id: '남' },
        },
      }),
    );

    // ⚠️ 403이 아니다. 403으로 답하면 "그 id가 있긴 하다"를 알려 주는 셈이다.
    await expect(service.getOwnedQuestion('u1', 'q1')).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });

  it('없는 질문도 404다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findQuestionById.mockResolvedValue(null);

    await expect(service.getOwnedQuestion('u1', 'q1')).rejects.toMatchObject({
      code: 'NOT_FOUND',
    });
  });

  it('잠긴 장의 질문은 CHAPTER_LOCKED로 막는다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findQuestionById.mockResolvedValue(
      question({
        userChapter: {
          id: 'c3',
          status: ChapterStatus.LOCKED,
          user: { id: 'u1' },
        },
      }),
    );

    await expect(service.getOwnedQuestion('u1', 'q1')).rejects.toMatchObject({
      code: 'CHAPTER_LOCKED',
    });
  });

  it('끝난 장의 질문은 열어 준다 — 다시 읽을 수 있어야 한다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findQuestionById.mockResolvedValue(
      question({
        userChapter: {
          id: 'c1',
          status: ChapterStatus.DONE,
          user: { id: 'u1' },
        },
      }),
    );

    await expect(service.getOwnedQuestion('u1', 'q1')).resolves.toBeTruthy();
  });
});

describe('ChaptersService · 문구 수정', () => {
  it('답변 전이면 고칠 수 있고 고친 표시가 남는다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findQuestionById.mockResolvedValue(question());

    const result = await service.updateQuestionText('u1', 'q1', '새 문구');

    expect(result.text).toBe('새 문구');
    expect(chaptersRepository.saveQuestion).toHaveBeenCalledWith(
      expect.objectContaining({ isEdited: true }),
    );
  });

  it('이미 답한 질문의 문구는 못 고친다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findQuestionById.mockResolvedValue(
      question({ status: QuestionStatus.ANSWERED }),
    );

    // 문구를 바꾸면 이미 저장된 원고와 어긋난다.
    await expect(
      service.updateQuestionText('u1', 'q1', '새 문구'),
    ).rejects.toMatchObject({ code: 'ALREADY_ANSWERED' });
  });

  it('건너뛴 질문도 못 고친다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findQuestionById.mockResolvedValue(
      question({ status: QuestionStatus.SKIPPED }),
    );

    await expect(
      service.updateQuestionText('u1', 'q1', '새 문구'),
    ).rejects.toMatchObject({ code: 'ALREADY_ANSWERED' });
  });
});

describe('ChaptersService · 목록과 현재 질문', () => {
  it('다음 질문 제목은 진행 중인 장에만 붙는다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findAllByUser.mockResolvedValue([
      {
        id: 'c1',
        sortOrder: 1,
        title: '1장',
        status: ChapterStatus.DONE,
        answeredCount: 5,
        questionCount: 5,
      },
      {
        id: 'c2',
        sortOrder: 2,
        title: '2장',
        status: ChapterStatus.WRITING,
        answeredCount: 1,
        questionCount: 5,
      },
      {
        id: 'c3',
        sortOrder: 3,
        title: '3장',
        status: ChapterStatus.LOCKED,
        answeredCount: 0,
        questionCount: 6,
      },
    ]);
    chaptersRepository.findFirstPending.mockResolvedValue({
      text: '다음에 물어볼 것',
    });

    const items = await service.getChapters('u1');

    expect(items.map((i) => i.next_question_text)).toEqual([
      null,
      '다음에 물어볼 것',
      // 잠긴 장에 붙이면 아직 못 여는 질문을 미리 보여주는 셈이다.
      null,
    ]);
  });

  it('진행 중인 장이 없으면 현재 질문도 없다', async () => {
    const { service, chaptersRepository } = buildService();
    chaptersRepository.findWritingChapter.mockResolvedValue(null);

    // 앱은 이걸 204로 받아 "다 끝났다"로 읽는다.
    expect(await service.getCurrentQuestion('u1')).toBeNull();
  });
});
