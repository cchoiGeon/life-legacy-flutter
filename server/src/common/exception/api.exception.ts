import { HttpException } from '@nestjs/common';

import { ErrorCodeValue } from './error-code.const';

/**
 * 앱이 `code`로 분기해야 하는 에러.
 *
 * 그 외 단순 실패는 Nest 기본 예외로 충분하다 — 필터가 공통 포맷으로 바꾼다.
 */
export class ApiException extends HttpException {
  readonly code: string;

  constructor(errorCode: ErrorCodeValue, customMessage?: string) {
    super(
      { code: errorCode.code, message: customMessage ?? errorCode.message },
      errorCode.status,
    );
    this.code = errorCode.code;
  }
}
