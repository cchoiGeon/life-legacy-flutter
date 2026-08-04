import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { QuestionStatus } from 'src/chapters/const/question-status.enum';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';
import { InputMode } from '../const/answer.enum';
import { AnswersTransactionService } from './answers-transaction.service';

/**
 * 장 진행 — 답변 하나가 장을 닫고 다음 장을 여는 자리다.
 *
 * 여기가 틀어지면 사용자는 같은 질문을 계속 다시 받거나(안 닫힘), 아직
 * 못 열 장이 열린다.
 */
function buildService(managerOverrides: Record<string, jest.Mock> = {}) {
  const chapter = {
    id: 'c1',
    sortOrder: 1,
    questionCount: 5,
    user: { id: 'u1' },
  };
  const nextChapter = { id: 'c2', sortOrder: 2 };

  const updates: { entity: unknown; where: unknown; set: unknown }[] = [];

  const manager = {
    save: jest.fn().mockImplementation((v: unknown) => Promise.resolve(v)),
    create: jest.fn().mockImplementation((_e: unknown, v: unknown) => v),
    delete: jest.fn().mockResolvedValue(undefined),
    findOne: jest.fn().mockResolvedValue(chapter),
    count: jest.fn().mockResolvedValue(0),
    update: jest.fn().mockImplementation((entity, where, set) => {
      updates.push({ entity, where, set });
      return Promise.resolve(undefined);
    }),
    createQueryBuilder: jest.fn().mockReturnValue({
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      getOne: jest.fn().mockResolvedValue(nextChapter),
    }),
    ...managerOverrides,
  };

  const dataSource = {
    transaction: jest
      .fn()
      .mockImplementation((cb: (m: unknown) => unknown) => cb(manager)),
  };

  return {
    service: new AnswersTransactionService(dataSource as never),
    manager,
    updates,
    nextChapter,
  };
}

const commitInput = () => ({
  question: {
    id: 'q1',
    text: '질문',
    userChapter: { id: 'c1' },
  } as never,
  draft: {
    firstText: '원문',
    firstInputMode: InputMode.VOICE,
    firstSpokenSeconds: 30,
  } as never,
  followups: [
    {
      seq: 1,
      questionText: '꼬리질문',
      answerText: '꼬리답변',
      inputMode: InputMode.KEYBOARD,
      spokenSeconds: null,
    },
  ],
  polishedText: '다듬은 글',
});

describe('AnswersTransactionService · 확정 저장', () => {
  it('마지막 질문을 답하면 장을 닫고 다음 장을 연다', async () => {
    const { service, updates, nextChapter } = buildService();

    const result = await service.commitAnswer(commitInput());

    expect(result.chapterCompleted).toBe(true);

    const closed = updates.find(
      (u) => (u.set as { status?: string }).status === ChapterStatus.DONE,
    );
    expect(closed).toBeTruthy();

    const opened = updates.find(
      (u) => (u.set as { status?: string }).status === ChapterStatus.WRITING,
    );
    expect(opened?.where).toEqual({ id: nextChapter.id });
  });

  it('남은 질문이 있으면 장을 닫지 않고 개수만 올린다', async () => {
    const { service, updates } = buildService({
      count: jest.fn().mockResolvedValue(2),
    });

    const result = await service.commitAnswer(commitInput());

    expect(result.chapterCompleted).toBe(false);
    expect(
      updates.some(
        (u) => (u.set as { status?: string }).status === ChapterStatus.DONE,
      ),
    ).toBe(false);
    // 5문항 중 2개 남았으면 3개 답한 것이다.
    expect(
      updates.some(
        (u) => (u.set as { answeredCount?: number }).answeredCount === 3,
      ),
    ).toBe(true);
  });

  it('마지막 장을 끝내면 열 다음 장이 없다', async () => {
    const { service, updates } = buildService({
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(null),
      }),
    });

    const result = await service.commitAnswer(commitInput());

    expect(result.chapterCompleted).toBe(true);
    expect(
      updates.some(
        (u) => (u.set as { status?: string }).status === ChapterStatus.WRITING,
      ),
    ).toBe(false);
  });

  it('확정 저장하면 초안을 지운다', async () => {
    const { service, manager } = buildService();

    await service.commitAnswer(commitInput());

    expect(manager.delete).toHaveBeenCalled();
  });
});

describe('AnswersTransactionService · 건너뛰기', () => {
  it('건너뛴 질문도 장 완료 개수에는 들어간다', async () => {
    const { service, updates } = buildService();

    const result = await service.skipQuestion({
      id: 'q1',
      userChapter: { id: 'c1' },
    } as never);

    // 개수에 넣지 않으면 건너뛴 장이 영영 안 끝난다.
    expect(result.chapterCompleted).toBe(true);
    expect(
      updates.some(
        (u) => (u.set as { status?: string }).status === QuestionStatus.SKIPPED,
      ),
    ).toBe(true);
  });

  it('장을 못 찾으면 진행을 옮기지 않는다', async () => {
    const { service } = buildService({
      findOne: jest.fn().mockResolvedValue(null),
    });

    const result = await service.skipQuestion({
      id: 'q1',
      userChapter: { id: 'c1' },
    } as never);

    expect(result.chapterCompleted).toBe(false);
  });
});

// 타입만 쓰고 값은 안 쓰는 import를 린트가 잡지 않도록 참조를 남긴다.
void ({} as UserChapterModel | undefined);
