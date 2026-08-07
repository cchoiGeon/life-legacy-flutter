import { QnaService } from './qna.service';
import { QnaStatus } from 'src/common/const/qna-status.enum';

function buildService(stored: { rows?: unknown[] } = {}) {
  const rows = stored.rows ?? [];
  const qna = {
    create: jest.fn((data: unknown) => ({ ...(data as object) })),
    save: jest.fn(async (row: { id?: string; createdAt?: Date }) => ({
      id: row.id ?? 'q1',
      createdAt: row.createdAt ?? new Date('2026-08-06T00:00:00.000Z'),
      answeredAt: null,
      ...row,
    })),
    find: jest.fn().mockResolvedValue(rows),
  };

  return {
    service: new QnaService(qna as never),
    qna,
  };
}

describe('QnaService', () => {
  it('FAQ는 카테고리와 섹션을 함께 돌려준다', () => {
    const { service } = buildService();
    const faq = service.getFaq();

    expect(faq.categories.length).toBeGreaterThan(0);
    expect(faq.sections[0].items[0].question).toBeTruthy();
  });

  it('문의를 등록하면 pending으로 저장한다', async () => {
    const { service, qna } = buildService();

    const created = await service.create('u1', {
      question: '음성 입력이 안 돼요. 권한은 허용했어요.',
      category: 'voice',
    });

    expect(created.status).toBe(QnaStatus.PENDING);
    expect(qna.save).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'u1',
        category: 'voice',
        status: QnaStatus.PENDING,
      }),
    );
  });

  it('허용되지 않은 카테고리는 거절한다', async () => {
    const { service } = buildService();

    await expect(
      service.create('u1', {
        question: '충분히 긴 문의 본문입니다.',
        category: 'not-a-real-category',
      }),
    ).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'INVALID_REQUEST' }),
    });
  });

  it('공개 목록은 published이고 답변이 있는 것만 남긴다', async () => {
    const { service, qna } = buildService({
      rows: [
        {
          id: 'a',
          category: 'other',
          question: '공개된 질문',
          status: QnaStatus.PUBLISHED,
          answer: '공개된 답',
          publishedAt: new Date('2026-08-01T00:00:00.000Z'),
          createdAt: new Date('2026-07-01T00:00:00.000Z'),
        },
        {
          id: 'b',
          category: null,
          question: '답 없는 게시',
          status: QnaStatus.PUBLISHED,
          answer: '   ',
          publishedAt: new Date('2026-08-02T00:00:00.000Z'),
          createdAt: new Date('2026-07-02T00:00:00.000Z'),
        },
      ],
    });

    const items = await service.listPublished();

    expect(qna.find).toHaveBeenCalled();
    expect(items).toHaveLength(1);
    expect(items[0]).toEqual(
      expect.objectContaining({
        id: 'a',
        question: '공개된 질문',
        answer: '공개된 답',
      }),
    );
    expect(items[0]).not.toHaveProperty('admin_note');
  });
});
