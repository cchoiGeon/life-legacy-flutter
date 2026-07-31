import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

/**
 * 운영에서는 Basic Auth로 보호하고, 계정 환경변수가 없으면 문서를 띄우지
 * 않는다. 자서전 API는 개인 기록을 다루므로 스펙조차 공개하지 않는다.
 */
export function setupSwagger(app: INestApplication) {
  if (process.env.NODE_ENV === 'production' && !process.env.SWAGGER_USER) {
    return;
  }

  const config = new DocumentBuilder()
    .setTitle('LifeLegacy API')
    .setDescription('앱(Flutter) 기준 서버 계약. docs/api-spec.md 참조')
    .setVersion('1.0')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      'access-token',
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document, {
    jsonDocumentUrl: 'api-json',
    yamlDocumentUrl: 'api.yaml',
  });
}
