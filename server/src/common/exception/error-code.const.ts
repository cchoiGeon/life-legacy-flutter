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
    /** api-spec §0.4 — OCTOMO 인증 세션이 아직 verified가 아님 */
    VERIFICATION_NOT_COMPLETED: {
      status: 401,
      code: 'VERIFICATION_NOT_COMPLETED',
      message: '인증이 완료되지 않았어요',
    },
    /** api-spec §0.4 — OCTOMO 인증 세션 만료 */
    VERIFICATION_EXPIRED: {
      status: 410,
      code: 'VERIFICATION_EXPIRED',
      message: '인증 유효시간이 지났어요. 다시 시작해 주세요',
    },
    /** api-spec §0.4 — 필수 약관 미동의 */
    CONSENT_REQUIRED: {
      status: 409,
      code: 'CONSENT_REQUIRED',
      message: '필수 약관에 동의해 주세요',
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
    SYNTHESIZE_FAILED: {
      status: 422,
      code: 'SYNTHESIZE_FAILED',
      message: '원고를 만들지 못했어요. 잠시 후 다시 시도해 주세요',
    },
    VERSION_CONFLICT: {
      status: 409,
      code: 'VERSION_CONFLICT',
      message: '다른 곳에서 먼저 고친 원고가 있어요. 다시 불러와 주세요',
    },
    TTS_FAILED: {
      status: 502,
      code: 'TTS_FAILED',
      message: '음성을 만들지 못했어요. 잠시 후 다시 시도해 주세요',
    },
    STT_FAILED: {
      status: 502,
      code: 'STT_FAILED',
      message: '말씀을 알아듣지 못했어요. 다시 한 번 말씀해 주세요',
    },
  },

  EBOOK: {
    CHAPTER_NOT_REVIEWED: {
      status: 403,
      code: 'CHAPTER_NOT_REVIEWED',
      message: '챕터 리뷰를 저장하면 전자책을 확인할 수 있어요',
    },
    NOT_READY: {
      status: 404,
      code: 'EBOOK_NOT_READY',
      message: '전자책 파일을 먼저 만들어 주세요',
    },
    GENERATE_FAILED: {
      status: 422,
      code: 'EBOOK_GENERATE_FAILED',
      message: '전자책을 만들지 못했어요. 잠시 후 다시 시도해 주세요',
    },
    TITLE_PROGRESS: {
      status: 403,
      code: 'TITLE_PROGRESS_REQUIRED',
      message: '전체 작성 진행률 80% 이상에서 제목 추천을 쓸 수 있어요',
    },
  },

  PLAN: {
    PLAN_REQUIRED: {
      status: 403,
      code: 'PLAN_REQUIRED',
      message: '유료 플랜에서 이용할 수 있어요',
    },
    QUOTA_EXCEEDED: {
      status: 429,
      code: 'QUOTA_EXCEEDED',
      message: '생성 횟수를 모두 썼어요',
    },
  },

  AUDIOBOOK: {
    CHAPTER_NOT_REVIEWED: {
      status: 409,
      code: 'CHAPTER_NOT_REVIEWED',
      message: '챕터 리뷰를 저장한 뒤 음성책을 만들 수 있어요',
    },
    JOB_IN_PROGRESS: {
      status: 409,
      code: 'JOB_IN_PROGRESS',
      message: '이미 만들고 있는 음성책이 있어요',
    },
    NOT_READY: {
      status: 404,
      code: 'AUDIOBOOK_NOT_READY',
      message: '음성책 파일을 먼저 만들어 주세요',
    },
    TTS_FAILED: {
      status: 502,
      code: 'AUDIOBOOK_TTS_FAILED',
      message: '음성책을 만들지 못했어요. 잠시 후 다시 시도해 주세요',
    },
  },
} as const;
