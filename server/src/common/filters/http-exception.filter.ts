import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

import { ERROR_CODE } from '../exception/error-code.const';

/**
 * 모든 예외를 api-spec §0.3의 실패 포맷으로 바꾼다.
 *
 * ```json
 * { "code": "INVALID_CODE", "message": "인증번호가 일치하지 않아요" }
 * ```
 *
 * ⚠️ 표준 구조(project-conventions §5.3)는 `{statusCode, message, data}`로
 *    한 겹 더 감싸지만 **여기서는 감싸지 않는다.** 앱의 `ApiException`이
 *    최상위 `code`·`message`를 읽도록 이미 구현·테스트돼 있다.
 *
 * 에러 1건 = 로그 1줄. 5xx만 스택을 붙이고 4xx는 warn 한 줄로 남겨 노이즈를
 * 줄인다.
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('Exception');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const { status, code, message } = this.normalize(exception);

    const line = `${request.method} ${request.url} → ${status} | ${code} | ${message}`;
    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(line, (exception as Error)?.stack);
    } else {
      this.logger.warn(line);
    }

    response.status(status).json({ code, message });
  }

  private normalize(exception: unknown): {
    status: number;
    code: string;
    message: string;
  } {
    if (!(exception instanceof HttpException)) {
      const fallback = ERROR_CODE.COMMON.SERVER_ERROR;
      return { ...fallback };
    }

    const status = exception.getStatus();
    const body = exception.getResponse();

    // ApiException이 심어 둔 { code, message }
    if (typeof body === 'object' && body !== null && 'code' in body) {
      const shaped = body as { code: string; message: string };
      return { status, code: shaped.code, message: shaped.message };
    }

    // ValidationPipe는 message를 배열로 준다. 앱은 문장 하나만 띄우므로
    // 개발자용 상세를 그대로 내보내지 않고 공통 문구로 바꾼다.
    if (status === HttpStatus.BAD_REQUEST) {
      this.logger.warn(`검증 실패 상세: ${JSON.stringify(body)}`);
      return { status, ...trim(ERROR_CODE.COMMON.INVALID_REQUEST) };
    }

    const known = KNOWN_BY_STATUS[status];
    if (known) {
      return { status, ...trim(known) };
    }

    return { status, ...trim(ERROR_CODE.COMMON.SERVER_ERROR) };
  }
}

function trim(errorCode: { code: string; message: string }) {
  return { code: errorCode.code, message: errorCode.message };
}

/** Nest 기본 예외(NotFoundException 등)를 앱이 아는 코드로 옮긴다. */
const KNOWN_BY_STATUS: Record<number, { code: string; message: string }> = {
  [HttpStatus.UNAUTHORIZED]: ERROR_CODE.AUTH.UNAUTHORIZED,
  [HttpStatus.NOT_FOUND]: ERROR_CODE.COMMON.NOT_FOUND,
  [HttpStatus.TOO_MANY_REQUESTS]: ERROR_CODE.COMMON.TOO_MANY_REQUESTS,
};
