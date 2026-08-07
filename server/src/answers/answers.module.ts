import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AiModule } from 'src/ai/ai.module';
import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { ChaptersModule } from 'src/chapters/chapters.module';
import { NotificationsModule } from 'src/notifications/notifications.module';
import { AnswersController } from './answers.controller';
import { AnswerDraftModel } from './entities/answer-draft.entity';
import { AnswerFollowupModel } from './entities/answer-followup.entity';
import { AnswerModel } from './entities/answer.entity';
import { AnswersRepository } from './repositories/answers.repository';
import { AnswersService } from './services/answers.service';
import { AnswersTransactionService } from './services/answers-transaction.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      AnswerModel,
      AnswerFollowupModel,
      AnswerDraftModel,
    ]),
    AuthGuardModule,
    AiModule,
    ChaptersModule,
    forwardRef(() => NotificationsModule),
  ],
  controllers: [AnswersController],
  providers: [AnswersService, AnswersTransactionService, AnswersRepository],
  exports: [AnswersService, AnswersRepository],
})
export class AnswersModule {}
