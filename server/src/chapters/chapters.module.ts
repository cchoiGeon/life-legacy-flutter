import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AnswersModule } from 'src/answers/answers.module';
import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { ChaptersController } from './chapters.controller';
import { UserChapterModel } from './entities/user-chapter.entity';
import { UserQuestionModel } from './entities/user-question.entity';
import { ChaptersRepository } from './repositories/chapters.repository';
import { ChaptersService } from './services/chapters.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserChapterModel, UserQuestionModel]),
    AuthGuardModule,
    // 컨트롤러가 저장된 답변을 함께 실어 주고, answers는 장 진행을 물어본다.
    forwardRef(() => AnswersModule),
  ],
  controllers: [ChaptersController],
  providers: [ChaptersService, ChaptersRepository],
  exports: [ChaptersService, ChaptersRepository],
})
export class ChaptersModule {}
