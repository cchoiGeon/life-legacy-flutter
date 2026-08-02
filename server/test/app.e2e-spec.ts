import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';

import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';

/**
 * 부팅 배선을 확인한다 — 단위 spec으로는 못 잡는 것들이다.
 *
 * 프리픽스가 빠지거나, 필터가 안 붙어 응답 모양이 `{statusCode, message}`로
 * 돌아가거나, 가드가 등록되지 않아도 단위 테스트는 전부 통과한다. 그런데
 * 앱은 **첫 화면부터** 못 넘어간다.
 *
 * ⚠️ 로컬 PostgreSQL이 떠 있어야 한다. `npm run test:e2e`
 */
describe('부팅 배선 (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    // main.ts와 같은 순서로 붙인다. 여기서 어긋나면 테스트가 실제 서버와
    // 다른 것을 재게 된다.
    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('v1', { exclude: ['health'] });
    app.useGlobalFilters(new HttpExceptionFilter());
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('헬스체크는 프리픽스 밖에 있다', async () => {
    await request(app.getHttpServer()).get('/health').expect(200);
    await request(app.getHttpServer()).get('/v1/health').expect(404);
  });

  it('보호된 라우트는 토큰 없이 401 UNAUTHORIZED', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/users/me')
      .expect(401);

    // 만료(TOKEN_EXPIRED)와 구분돼야 한다 — 앱이 이 둘로 갱신 여부를 가른다.
    expect(res.body).toEqual({
      code: 'UNAUTHORIZED',
      message: expect.any(String) as string,
    });
  });

  it('실패 응답에는 래퍼가 없다 — code·message가 최상위에 온다', async () => {
    const res = await request(app.getHttpServer())
      .post('/v1/auth/phone/verify')
      .send({ phone: '01012345678' })
      .expect(400);

    expect(Object.keys(res.body as object).sort()).toEqual(['code', 'message']);
    // ValidationPipe의 영문 상세를 그대로 내보내면 안 된다.
    expect(res.body).toMatchObject({ code: 'INVALID_REQUEST' });
  });

  it('목록 응답은 items로만 감싼다', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/intro/questions')
      .expect(401);

    // 인증 전이라 401이지만, 이 경로가 살아 있다는 것까지는 확인된다.
    expect(res.body).toMatchObject({ code: 'UNAUTHORIZED' });
  });
});
