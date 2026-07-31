export enum ChapterStatus {
  /** 앞 장을 끝내야 열린다 */
  LOCKED = 'locked',
  /** 작성 중. 사용자당 최대 1개 */
  WRITING = 'writing',
  /** 모든 질문 완료 */
  DONE = 'done',
}
