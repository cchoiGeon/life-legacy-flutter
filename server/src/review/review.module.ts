import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AiModule } from 'src/ai/ai.module';
import { AnswersModule } from 'src/answers/answers.module';
import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { BookAccessModule } from 'src/book/book-access.module';
import { ChaptersModule } from 'src/chapters/chapters.module';
import { EntitlementModule } from 'src/entitlement/entitlement.module';
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';
import { MediaPlacementModel } from 'src/media/entities/media-placement.entity';
import { VoiceModule } from 'src/voice/voice.module';
import { ChapterReviewModel } from './entities/chapter-review.entity';
import { ReviewController } from './review.controller';
import { ReviewService } from './services/review.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ChapterReviewModel,
      MediaAssetModel,
      MediaPlacementModel,
    ]),
    AuthGuardModule,
    BookAccessModule,
    ChaptersModule,
    AnswersModule,
    AiModule,
    VoiceModule,
    EntitlementModule,
  ],
  controllers: [ReviewController],
  providers: [ReviewService],
  exports: [ReviewService],
})
export class ReviewModule {}
