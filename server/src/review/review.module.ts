import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AiModule } from 'src/ai/ai.module';
import { AnswersModule } from 'src/answers/answers.module';
import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { BookAccessModule } from 'src/book/book-access.module';
import { ChaptersModule } from 'src/chapters/chapters.module';
import { VoiceModule } from 'src/voice/voice.module';
import { ChapterReviewModel } from './entities/chapter-review.entity';
import { ReviewController } from './review.controller';
import { ReviewService } from './services/review.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([ChapterReviewModel]),
    AuthGuardModule,
    BookAccessModule,
    ChaptersModule,
    AnswersModule,
    AiModule,
    VoiceModule,
  ],
  controllers: [ReviewController],
  providers: [ReviewService],
  exports: [ReviewService],
})
export class ReviewModule {}
