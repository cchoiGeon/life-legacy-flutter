/** 액세스 토큰 수명 — api-spec §0.2 */
export const ACCESS_TOKEN_TTL_SECONDS = 60 * 60;

/** 리프레시 토큰 수명 60일 */
export const REFRESH_TOKEN_TTL_SECONDS = 60 * 60 * 24 * 60;

/** 인증번호 유효 시간 — 화면의 "2분 47초 남음" */
export const VERIFICATION_TTL_SECONDS = 180;

/**
 * "다시 받기"가 열릴 때까지.
 *
 * ⚠️ 만료(180)와 **따로 센다.** 하나로 묶으면 문자가 안 온 사람이 번호가
 *    만료될 때까지 아무것도 못 하고 기다리게 된다.
 */
export const VERIFICATION_RESEND_AFTER_SECONDS = 30;

/** 한 번호가 이 횟수를 넘겨 틀리면 그 인증번호는 폐기한다 */
export const VERIFICATION_MAX_ATTEMPTS = 5;
