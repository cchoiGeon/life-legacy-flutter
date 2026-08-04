import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { BookModel } from 'src/book/entities/book.entity';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';
import { UserQuestionModel } from 'src/chapters/entities/user-question.entity';
import { UsersModule } from 'src/users/users.module';
import { CaseDefinitionModel } from './entities/case-definition.entity';
import { IntroChoiceModel } from './entities/intro-choice.entity';
import { IntroQuestionModel } from './entities/intro-question.entity';
import { UserIntroAnswerModel } from './entities/user-intro-answer.entity';
import { UserProfileModel } from './entities/user-profile.entity';
import { WritingPlanModel } from './entities/writing-plan.entity';
import { IntroController } from './intro.controller';
import { IntroRepository } from './repositories/intro.repository';
import { IntroService } from './services/intro.service';
import { IntroTransactionService } from './services/intro-transaction.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      IntroQuestionModel,
      IntroChoiceModel,
      UserIntroAnswerModel,
      CaseDefinitionModel,
      UserProfileModel,
      UserChapterModel,
      UserQuestionModel,
      BookModel,
      WritingPlanModel,
    ]),
    AuthGuardModule,
    UsersModule,
  ],
  controllers: [IntroController],
  providers: [IntroService, IntroTransactionService, IntroRepository],
  exports: [IntroService],
})
export class IntroModule {}
