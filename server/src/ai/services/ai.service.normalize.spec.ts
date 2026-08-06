import { normalizeFollowupText } from './ai.service';

describe('normalizeFollowupText', () => {
  it('이미 빈 줄로 나뉜 리액션+질문을 유지한다', () => {
    expect(
      normalizeFollowupText(
        '장면이 그려집니다. 마음에 남아 계신 것 같아요.\n\n그때 누가 함께 있었나요?',
      ),
    ).toBe(
      '장면이 그려집니다. 마음에 남아 계신 것 같아요.\n\n그때 누가 함께 있었나요?',
    );
  });

  it('한 줄로 이어 쓴 3문장을 리액션과 질문으로 나눈다', () => {
    expect(
      normalizeFollowupText(
        '장면이 그려집니다. 마음에 남아 계신 것 같아요. 그때 누가 함께 있었나요?',
      ),
    ).toBe(
      '장면이 그려집니다. 마음에 남아 계신 것 같아요.\n\n그때 누가 함께 있었나요?',
    );
  });

  it('여러 빈 줄·줄바꿈을 한 칸으로 정리한다', () => {
    expect(
      normalizeFollowupText(
        '장면이 그려집니다.\n마음에 남아 계신 것 같아요.\n\n\n그때 누가 함께 있었나요?',
      ),
    ).toBe(
      '장면이 그려집니다. 마음에 남아 계신 것 같아요.\n\n그때 누가 함께 있었나요?',
    );
  });
});
