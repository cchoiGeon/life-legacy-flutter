import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';

/**
 * `Authorization: Bearer {access_token}` 검증.
 *
 * ⚠️ 만료는 `TOKEN_EXPIRED`, 그 외는 `UNAUTHORIZED`로 나눠 던진다.
 *    앱이 이 둘을 구분해서 만료일 때만 리프레시를 시도한다(api-spec §1.4).
 */
@Injectable()
export class AccessTokenGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request & { userId?: string }>();
    const token = extractBearer(request.headers.authorization);
    if (!token) {
      throw new ApiException(ERROR_CODE.AUTH.UNAUTHORIZED);
    }

    try {
      const payload = await this.jwtService.verifyAsync<{ sub: string }>(token, {
        secret: this.configService.getOrThrow<string>('JWT_ACCESS_SECRET'),
      });
      request.userId = payload.sub;
    } catch (error) {
      const expired = (error as Error)?.name === 'TokenExpiredError';
      throw new ApiException(
        expired ? ERROR_CODE.AUTH.TOKEN_EXPIRED : ERROR_CODE.AUTH.UNAUTHORIZED,
      );
    }

    return true;
  }
}

function extractBearer(header: string | undefined): string | null {
  if (!header) {
    return null;
  }

  const [scheme, token] = header.split(' ');
  return scheme === 'Bearer' && token ? token : null;
}
