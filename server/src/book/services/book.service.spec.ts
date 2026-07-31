import { ChapterStatus } from 'src/chapters/const/chapter-status.enum';
import { BookService } from './book.service';

/**
 * 쪽 나누기는 **서버가** 한다. 앱은 받은 대로 그린다.
 *
 * 그래서 "어떤 글이 실리고 어떻게 잘리는지"가 곧 계약이다.
 */
function buildService(
  options: {
    chapters?: unknown[];
    answersByChapter?: Record<string, unknown[]>;
  } = {},
) {
  const chaptersRepository = {
    findAllByUser: jest.fn().mockResolvedValue(options.chapters ?? []),
  };
  const answersRepository = {
    findPolishedByChapter: jest
      .fn()
      .mockImplementation((id: string) =>
        Promise.resolve(options.answersByChapter?.[id] ?? []),
      ),
    countAnsweredByUser: jest.fn().mockResolvedValue(0),
  };
  const usersService = {
    getOrThrow: jest.fn().mockResolvedValue({ name: '김영희' }),
  };

  return {
    service: new BookService(
      {} as never,
      chaptersRepository as never,
      answersRepository as never,
      usersService as never,
    ),
    answersRepository,
  };
}

const chapter = (id: string, order: number, status: ChapterStatus) => ({
  id,
  sortOrder: order,
  title: `${order}장`,
  status,
});

describe('BookService · 미리보기 쪽', () => {
  it('끝난 장만 싣는다', async () => {
    const { service, answersRepository } = buildService({
      chapters: [
        chapter('c1', 1, ChapterStatus.DONE),
        chapter('c2', 2, ChapterStatus.WRITING),
        chapter('c3', 3, ChapterStatus.LOCKED),
      ],
      answersByChapter: { c1: [{ polishedText: '가\n\n나' }] },
    });

    const pages = await service.getPages('u1');

    // 작성 중인 장을 실으면 아직 다듬지 않은 글이 책에 들어간다.
    expect(answersRepository.findPolishedByChapter).toHaveBeenCalledTimes(1);
    expect(pages.every((p) => p.chapter_order === 1)).toBe(true);
  });

  it('문단 셋마다 한 쪽으로 끊고 통쪽수를 매긴다', async () => {
    const { service } = buildService({
      chapters: [
        chapter('c1', 1, ChapterStatus.DONE),
        chapter('c2', 2, ChapterStatus.DONE),
      ],
      answersByChapter: {
        c1: [{ polishedText: '가\n\n나\n\n다\n\n라' }],
        c2: [{ polishedText: '마\n\n바' }],
      },
    });

    const pages = await service.getPages('u1');

    // 1장 4문단 → 2쪽, 2장 2문단 → 1쪽
    expect(pages.map((p) => p.page_number)).toEqual([1, 2, 3]);
    // 장이 바뀌어도 쪽 번호는 1로 돌아가지 않는다.
    expect(pages.map((p) => p.chapter_order)).toEqual([1, 1, 2]);
    // 앱이 쪽 하나만 들고도 "2 / 3쪽"을 그릴 수 있어야 한다.
    expect(pages.every((p) => p.total_pages === 3)).toBe(true);
  });

  it('윤문이 없으면 사용자 원문으로 채운다', async () => {
    const { service } = buildService({
      chapters: [chapter('c1', 1, ChapterStatus.DONE)],
      answersByChapter: {
        c1: [{ polishedText: null, firstText: '원문만 있다' }],
      },
    });

    // 윤문이 실패한 채로 저장된 답변도 책에서 빠지면 안 된다.
    expect((await service.getPages('u1'))[0].paragraphs).toEqual([
      '원문만 있다',
    ]);
  });

  it('빈 문단은 버린다', async () => {
    const { service } = buildService({
      chapters: [chapter('c1', 1, ChapterStatus.DONE)],
      answersByChapter: { c1: [{ polishedText: '가\n\n\n\n   \n\n나' }] },
    });

    expect((await service.getPages('u1'))[0].paragraphs).toEqual(['가', '나']);
  });
});

describe('BookService · 책 요약', () => {
  it('모든 장이 끝나야 완성이다', async () => {
    const { service } = buildService({
      chapters: [
        chapter('c1', 1, ChapterStatus.DONE),
        chapter('c2', 2, ChapterStatus.WRITING),
      ],
    });

    expect((await service.getBook('u1')).is_complete).toBe(false);
  });

  it('장이 하나도 없으면 완성이 아니다', async () => {
    const { service } = buildService({ chapters: [] });

    // every()는 빈 배열에서 true다. 목차도 안 만든 사람이 "완성"이 되면 안 된다.
    expect((await service.getBook('u1')).is_complete).toBe(false);
  });

  it('사진 수는 v1에서 항상 0이다', async () => {
    const { service } = buildService({ chapters: [] });

    expect((await service.getBook('u1')).photo_count).toBe(0);
  });
});
