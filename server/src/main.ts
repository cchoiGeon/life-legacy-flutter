import {
  ClassSerializerInterceptor,
  Logger,
  ValidationPipe,
} from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from './app.module';
import { setupSwagger } from './common/config/swagger.config';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  try {
    const app = await NestFactory.create(AppModule, {
      logger: ['error', 'warn', 'log', 'debug', 'verbose'],
    });

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

    // ⚠️ ResponseInterceptor를 두지 않는다. 앱 계약(api-spec §0.3)이
    //    래퍼 없는 평평한 응답이다.
    app.useGlobalInterceptors(
      new ClassSerializerInterceptor(app.get('Reflector')),
    );

    setupSwagger(app);

    const port = Number(process.env.PORT ?? 3000);
    await app.listen(port, '0.0.0.0');
    logger.log(`LifeLegacy API listening on :${port}`);
  } catch (error) {
    logger.error('Failed to bootstrap the application');
    logger.error(error);
    process.exit(1);
  }
}

void bootstrap();
