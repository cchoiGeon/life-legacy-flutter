import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AppController } from './app.controller';
import { AnswersModule } from './answers/answers.module';
import { AuthModule } from './auth/auth.module';
import { BookModule } from './book/book.module';
import { ChaptersModule } from './chapters/chapters.module';
import { HomeModule } from './home/home.module';
import { IntroModule } from './intro/intro.module';
import { NotificationsModule } from './notifications/notifications.module';
import { SettingsModule } from './settings/settings.module';
import { AiModule } from './ai/ai.module';
import { CatalogModule } from './catalog/catalog.module';
import { ReviewModule } from './review/review.module';
import { AudiobookModule } from './audiobook/audiobook.module';
import { QnaModule } from './qna/qna.module';
import { UsersModule } from './users/users.module';
import { VoiceModule } from './voice/voice.module';
import { CouponModule } from './coupon/coupon.module';
import { PrintOrderModule } from './print-order/print-order.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [`.env.${process.env.NODE_ENV || 'local'}`, '.env'],
    }),

    // 레이트리밋은 전역 가드로 걸지 않는다 — 인증·AI 라우트에만 붙인다
    // (api-spec §0.5의 대상별 제한이 서로 다르다).
    ThrottlerModule.forRoot([{ name: 'default', ttl: 10_000, limit: 100 }]),

    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        host: config.get<string>('DB_HOST', 'localhost'),
        port: Number(config.get<string>('DB_PORT', '5432')),
        username: config.get<string>('DB_USERNAME'),
        password: config.get<string>('DB_PASSWORD'),
        database: config.get<string>('DB_DATABASE'),
        // ⚠️ 표준 구조는 entities 배열에 하나씩 등록하지만 글롭을 쓴다 —
        //    24개를 손으로 적으면 새 엔티티를 빠뜨렸을 때 조용히 테이블만
        //    안 생기고, 그 사실이 런타임에야 드러난다.
        entities: [__dirname + '/**/*.entity{.ts,.js}'],
        // 운영에서는 항상 false. DDL은 수동 적용한다.
        synchronize: config.get<string>('DB_SYNCHRONIZE') === 'true',
        // 기본값(max 10, 무한 대기)은 잠금 상황에서 요청이 수십 초 매달리는
        // 원인이 된다.
        extra: {
          max: Number(config.get<string>('DB_POOL_MAX', '20')),
          connectionTimeoutMillis: 5000,
          statement_timeout: 15000,
          lock_timeout: 5000,
          idleTimeoutMillis: 30000,
        },
      }),
    }),

    AiModule,
    CatalogModule,
    UsersModule,
    AuthModule,
    IntroModule,
    ChaptersModule,
    AnswersModule,
    HomeModule,
    BookModule,
    ReviewModule,
    AudiobookModule,
    VoiceModule,
    NotificationsModule,
    SettingsModule,
    CouponModule,
    PrintOrderModule,
    QnaModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
