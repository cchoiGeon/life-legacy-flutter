import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';

import { AccessTokenGuard } from './guard/access-token.guard';

/**
 * 액세스 토큰 가드만 담은 작은 모듈.
 *
 * ⚠️ 가드는 `@UseGuards()`를 쓴 **컨트롤러가 속한 모듈**에서 생성된다.
 *    그래서 AuthModule에서 export하는 것만으로는 부족하다 — 가드를 쓰는
 *    모듈마다 이 모듈을 import해야 JwtService가 함께 따라온다.
 *
 * AuthModule과 분리한 이유: AuthModule은 UsersModule을 import하는데,
 * UsersModule이 다시 AuthModule을 import하면 순환이 된다. 가드는 사용자
 * 도메인을 몰라도 되므로 여기로 뺐다.
 */
@Module({
  imports: [JwtModule.register({})],
  providers: [AccessTokenGuard],
  // ⚠️ JwtModule도 함께 내보낸다. 가드는 `@UseGuards()`를 쓴 컨트롤러의
  //    모듈 컨텍스트에서 생성되므로, 가드만 내보내면 그 모듈에서 JwtService를
  //    찾지 못해 부팅이 죽는다.
  exports: [AccessTokenGuard, JwtModule],
})
export class AuthGuardModule {}
