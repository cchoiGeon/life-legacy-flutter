export enum InputMode {
  VOICE = 'voice',
  KEYBOARD = 'keyboard',
}

export enum DraftPhase {
  /** 1차 답변 저장됨, 꼬리질문 생성 대기/완료 */
  FIRST = 'first',
  /** 꼬리질문 제시됨, 꼬리답변 대기 */
  FOLLOWUP = 'followup',
}

export enum PolishStatus {
  OK = 'ok',
  /** 윤문 실패. 원문은 살아 있다 */
  FAILED = 'failed',
}
