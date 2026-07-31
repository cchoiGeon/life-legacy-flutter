import { ExecutionContext, createParamDecorator } from '@nestjs/common';

/** 가드가 심어 둔 사용자 id를 컨트롤러 인자로 꺼낸다 */
export const UserId = createParamDecorator(
  (_data: unknown, context: ExecutionContext): string => {
    const request = context.switchToHttp().getRequest<{ userId: string }>();
    return request.userId;
  },
);
