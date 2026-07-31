export type ErrorCodeValue = {
  status: number;
  code: string;
  message: string;
};

/**
 * api-spec §0.4의 에러 코드 표를 그대로 옮긴 것.
 *
 * ⚠️ `message`는 **앱이 사용자에게 그대로 띄우는 한국어 문장**이다.
 *    개발자용 상세를 여기 넣지 않는다 — 로그로 남긴다.
 *
 * ⚠️ 표준 구조의 `USER_001` 같은 도메인 일련번호를 쓰지 않는다. 앱이 이미
 *    `INVALID_CODE` 같은 문자열로 분기하도록 구현돼 있다(api-spec §0.3).
 */
export const ERROR_CODE = {
  COMMON: {
    INVALID_REQUEST: {
      status: 400,
      code: 'INVALID_REQUEST',
      message: '요청 내용을 다시 확인해 주세요',
    },
    NOT_FOUND: {
      status: 404,
      code: 'NOT_FOUND',
      message: '찾을 수 없어요',
    },
    TOO_MANY_REQUESTS: {
      status: 429,
      code: 'TOO_MANY_REQUESTS',
      message: '잠시 후 다시 시도해 주세요',
    },
    SERVER_ERROR: {
      status: 500,
      code: 'SERVER_ERROR',
      message: '잠시 문제가 생겼어요. 다시 시도해 주세요',
    },
  },

  AUTH: {
    UNAUTHORIZED: {
      status: 401,
      code: 'UNAUTHORIZED',
      message: '다시 로그인해 주세요',
    },
    TOKEN_EXPIRED: {
      status: 401,
      code: 'TOKEN_EXPIRED',
      message: '다시 로그인해 주세요',
    },
    INVALID_CODE: {
      status: 401,
      code: 'INVALID_CODE',
      message: '인증번호가 일치하지 않아요',
    },
    CODE_EXPIRED: {
      status: 410,
      code: 'CODE_EXPIRED',
      message: '인증번호 유효시간이 지났어요. 다시 받아 주세요',
    },
  },

  INTRO: {
    INTRO_REQUIRED: {
      status: 403,
      code: 'INTRO_REQUIRED',
      message: '자기소개를 먼저 마쳐 주세요',
    },
    TOC_ALREADY_CONFIRMED: {
      status: 409,
      code: 'TOC_ALREADY_CONFIRMED',
      message: '이미 목차를 확정하셨어요',
    },
  },

  WRITE: {
    CHAPTER_LOCKED: {
      status: 409,
      code: 'CHAPTER_LOCKED',
      message: '앞 장을 먼저 마쳐 주세요',
    },
    ALREADY_ANSWERED: {
      status: 409,
      code: 'ALREADY_ANSWERED',
      message: '이미 답하신 질문이에요',
    },
    /**
     * 꼬리질문을 만들지 못했다. 서버가 1차 답변 초안을 **버리므로** 앱은
     * 질문부터 다시 받는다 (api-spec §5.3).
     */
    FOLLOWUP_FAILED: {
      status: 422,
      code: 'FOLLOWUP_FAILED',
      message: '질문을 만들지 못했어요. 잠시 후 다시 시도해 주세요',
    },
    /**
     * 윤문에 실패했다. 초안은 **남겨 두므로** 앱은 같은 요청을 다시 보내면
     * 된다 (api-spec §5.4). 두 번 답한 이야기를 날리지 않는다.
     */
    POLISH_FAILED: {
      status: 422,
      code: 'POLISH_FAILED',
      message: '저장에 실패했어요. 다시 시도해 주세요',
    },
  },
} as const;
