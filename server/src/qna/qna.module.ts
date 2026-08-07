import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { QnaQuestionModel } from './entities/qna-question.entity';
import { FaqController, QnaController } from './qna.controller';
import { QnaService } from './services/qna.service';

@Module({
  imports: [TypeOrmModule.forFeature([QnaQuestionModel]), AuthGuardModule],
  controllers: [QnaController, FaqController],
  providers: [QnaService],
})
export class QnaModule {}
