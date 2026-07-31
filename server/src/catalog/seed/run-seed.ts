import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from 'src/app.module';
import { SeedService } from './seed.service';

/**
 * `npm run seed` 진입점.
 *
 * HTTP 서버를 띄우지 않고 애플리케이션 컨텍스트만 만든다 — 시드는 배포
 * 훅이나 손으로 돌리는 작업이라 포트를 잡을 이유가 없다.
 */
async function runSeed() {
  const logger = new Logger('Seed');
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });

  try {
    await app.get(SeedService).run();
    logger.log('시드 완료');
  } catch (error) {
    logger.error('시드 실패', error);
    process.exitCode = 1;
  } finally {
    await app.close();
  }
}

void runSeed();
