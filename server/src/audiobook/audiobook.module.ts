import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { BookAccessModule } from 'src/book/book-access.module';
import { ChaptersModule } from 'src/chapters/chapters.module';
import { EntitlementLedgerModel } from 'src/entitlement/entities/entitlement-ledger.entity';
import { EntitlementModule } from 'src/entitlement/entitlement.module';
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';
import { ChapterReviewModel } from 'src/review/entities/chapter-review.entity';
import { VoiceModule } from 'src/voice/voice.module';
import { AudiobookController } from './audiobook.controller';
import { AudiobookJobPartModel } from './entities/audiobook-job-part.entity';
import { AudiobookJobModel } from './entities/audiobook-job.entity';
import { BgmTrackModel } from './entities/bgm-track.entity';
import { AudiobookService } from './services/audiobook.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      AudiobookJobModel,
      AudiobookJobPartModel,
      BgmTrackModel,
      ChapterReviewModel,
      EntitlementLedgerModel,
      MediaAssetModel,
    ]),
    AuthGuardModule,
    BookAccessModule,
    ChaptersModule,
    EntitlementModule,
    VoiceModule,
  ],
  controllers: [AudiobookController],
  providers: [AudiobookService],
  exports: [AudiobookService],
})
export class AudiobookModule {}
