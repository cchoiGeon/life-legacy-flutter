import { QuestionStatus } from 'src/chapters/const/question-status.enum';
import { InputMode } from '../const/answer.enum';
import { AnswersService } from './answers.service';

/**
 * 작성 흐름의 **규칙**만 잰다.
 *
 * 가장 중요한 건 실패 두 갈래가 초안을 반대로 다룬다는 것이다 —
 * 꼬리질문 실패는 버리고, 윤문 실패는 남긴다. 이게 뒤집히면 사용자는
 * 답한 이야기를 잃거나, 화면에 없는 글이 저장된다.
 */
function buildService() {
  const answersRepository = {
    findAnswerByQuestion: jest.fn(),
    findDraftByQuestion: jest.fn(),
    saveDraft: jest.fn(),
    deleteDraft: jest.fn(),
  };
  const answersTransactionService = {
    commitAnswer: jest.fn().mockResolvedValue({ chapterCompleted: false }),
    skipQuestion: jest.fn().mockResolvedValue({ chapterCompleted: false }),
  };
  const chaptersService = {
    getOwnedQuestion: jest.fn(),
    getCurrentQuestion: jest.fn().mockResolvedValue(null),
  };
  const aiService = {
    generateFollowup: jest.fn().mockResolvedValue('요약\n\n질문?'),
    polish: jest.fn().mockResolvedValue('다듬은 글'),
  };

  const service = new AnswersService(
    answersRepository as never,
    answersTransactionService as never,
    chaptersService as never,
    aiService as never,
  );

  return {
    service,
    answersRepository,
    answersTransactionService,
    chaptersService,
    aiService,
  };
}

const question = (status = QuestionStatus.PENDING) => ({
  id: 'q1',
  text: '어릴 적 동네는 어땠나요?',
  status,
  userChapter: { id: 'c1', title: '탄생과 유아기 시절' },
});

const input = {
  text: '해남에서 태어났습니다',
  inputMode: InputMode.VOICE,
  spokenSeconds: 42,
};

describe('AnswersService · 1차 답변 → 꼬리질문', () => {
  it('초안으로만 두고 꼬리질문을 돌려준다', async () => {
    const {
      service,
      chaptersService,
      answersRepository,
      answersTransactionService,
    } = buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(question());

    const result = await service.submitFirstAnswer('u1', 'q1', input);

    expect(result.followup.text).toContain('질문?');
    expect(answersRepository.saveDraft).toHaveBeenCalledTimes(1);
    // 아직 확정이 아니다. 꼬리답변까지 받아야 저장한다.
    expect(answersTransactionService.commitAnswer).not.toHaveBeenCalled();
  });

  it('꼬리질문을 만들지 못하면 초안을 버리고 FOLLOWUP_FAILED를 던진다', async () => {
    const { service, chaptersService, aiService, answersRepository } =
      buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(question());
    aiService.generateFollowup.mockRejectedValue(new Error('모델 오류'));

    await expect(
      service.submitFirstAnswer('u1', 'q1', input),
    ).rejects.toMatchObject({ code: 'FOLLOWUP_FAILED' });

    // 화면에 없는 글을 서버가 들고 있으면 다시 답한 내용과 어긋난다.
    expect(answersRepository.deleteDraft).toHaveBeenCalledWith('q1');
    expect(answersRepository.saveDraft).not.toHaveBeenCalled();
  });

  it('모델이 한 번 흔들려도 다시 시도해서 살린다', async () => {
    const { service, chaptersService, aiService } = buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(question());
    aiService.generateFollowup
      .mockRejectedValueOnce(new Error('일시 오류'))
      .mockResolvedValueOnce('요약\n\n다시 만든 질문?');

    const result = await service.submitFirstAnswer('u1', 'q1', input);

    expect(result.followup.text).toContain('다시 만든 질문?');
    expect(aiService.generateFollowup).toHaveBeenCalledTimes(2);
  });

  it('이미 답한 질문에는 다시 답할 수 없다', async () => {
    const { service, chaptersService } = buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(
      question(QuestionStatus.ANSWERED),
    );

    await expect(
      service.submitFirstAnswer('u1', 'q1', input),
    ).rejects.toMatchObject({ code: 'ALREADY_ANSWERED' });
  });
});

describe('AnswersService · 꼬리답변 → 확정 저장', () => {
  const draft = {
    firstText: '해남에서 태어났습니다',
    firstInputMode: InputMode.VOICE,
    firstSpokenSeconds: 42,
    followupQuestionText: '누가 함께 계셨나요?',
    followupId: 'f1',
  };

  it('윤문한 글과 원문 둘을 함께 저장한다', async () => {
    const {
      service,
      chaptersService,
      answersRepository,
      answersTransactionService,
    } = buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(question());
    answersRepository.findDraftByQuestion.mockResolvedValue(draft);

    await service.submitFollowupAnswer('u1', 'q1', 'f1', {
      text: '어머니가 계셨습니다',
      inputMode: InputMode.KEYBOARD,
      spokenSeconds: null,
    });

    expect(answersTransactionService.commitAnswer).toHaveBeenCalledWith(
      expect.objectContaining({
        polishedText: '다듬은 글',
        followupAnswerText: '어머니가 계셨습니다',
      }),
    );
  });

  it('윤문에 실패하면 초안을 남긴 채 POLISH_FAILED를 던진다', async () => {
    const { service, chaptersService, answersRepository, aiService } =
      buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(question());
    answersRepository.findDraftByQuestion.mockResolvedValue(draft);
    aiService.polish.mockRejectedValue(new Error('모델 오류'));

    await expect(
      service.submitFollowupAnswer('u1', 'q1', 'f1', {
        text: '어머니가 계셨습니다',
        inputMode: InputMode.KEYBOARD,
        spokenSeconds: null,
      }),
    ).rejects.toMatchObject({ code: 'POLISH_FAILED' });

    // ⚠️ 꼬리질문 실패와 **반대**다. 두 번 답한 이야기를 날리지 않는다.
    //    앱이 같은 요청을 다시 보내면 그대로 이어서 저장된다.
    expect(answersRepository.deleteDraft).not.toHaveBeenCalled();
  });

  it('다른 꼬리질문 id로는 저장할 수 없다', async () => {
    const { service, chaptersService, answersRepository } = buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(question());
    answersRepository.findDraftByQuestion.mockResolvedValue(draft);

    await expect(
      service.submitFollowupAnswer('u1', 'q1', '다른-id', {
        text: '어머니가 계셨습니다',
        inputMode: InputMode.KEYBOARD,
        spokenSeconds: null,
      }),
    ).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });

  it('초안이 없으면 저장할 수 없다', async () => {
    const { service, chaptersService, answersRepository } = buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(question());
    answersRepository.findDraftByQuestion.mockResolvedValue(null);

    await expect(
      service.submitFollowupAnswer('u1', 'q1', 'f1', {
        text: '어머니가 계셨습니다',
        inputMode: InputMode.KEYBOARD,
        spokenSeconds: null,
      }),
    ).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });

  it('모든 장을 끝내면 next_question이 null이다', async () => {
    const { service, chaptersService, answersRepository } = buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(question());
    answersRepository.findDraftByQuestion.mockResolvedValue(draft);
    chaptersService.getCurrentQuestion.mockResolvedValue(null);

    const result = await service.submitFollowupAnswer('u1', 'q1', 'f1', {
      text: '어머니가 계셨습니다',
      inputMode: InputMode.KEYBOARD,
      spokenSeconds: null,
    });

    // 앱은 이걸 "다 끝났다"로 읽고 자서전 화면으로 간다.
    expect(result.next_question).toBeNull();
  });
});

describe('AnswersService · 건너뛰기와 조회', () => {
  it('건너뛰면 답변 없이 다음으로 넘어간다', async () => {
    const { service, chaptersService, answersTransactionService } =
      buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(question());

    await service.skipQuestion('u1', 'q1');

    expect(answersTransactionService.skipQuestion).toHaveBeenCalled();
  });

  it('이미 답한 질문은 건너뛸 수 없다', async () => {
    const { service, chaptersService } = buildService();
    chaptersService.getOwnedQuestion.mockResolvedValue(
      question(QuestionStatus.ANSWERED),
    );

    await expect(service.skipQuestion('u1', 'q1')).rejects.toMatchObject({
      code: 'ALREADY_ANSWERED',
    });
  });

  it('질문에 실어 주는 답변은 윤문 결과가 아니라 사용자 원문이다', async () => {
    const { service, answersRepository } = buildService();
    answersRepository.findAnswerByQuestion.mockResolvedValue({
      firstText: '사용자가 말한 그대로',
      polishedText: 'AI가 다듬은 글',
    });

    // 다듬은 글이 처음 보이는 곳은 자서전 미리보기다. 작성 화면이 아니다.
    expect(await service.findSavedAnswerText('q1')).toBe(
      '사용자가 말한 그대로',
    );
  });
});
