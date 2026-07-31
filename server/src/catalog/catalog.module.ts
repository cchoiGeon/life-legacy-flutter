import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { PromptTemplateModel } from 'src/ai/entities/prompt-template.entity';
import { CaseDefinitionModel } from 'src/intro/entities/case-definition.entity';
import { IntroChoiceModel } from 'src/intro/entities/intro-choice.entity';
import { IntroQuestionModel } from 'src/intro/entities/intro-question.entity';
import { ChapterTemplateModel } from './entities/chapter-template.entity';
import { QuestionTemplateModel } from './entities/question-template.entity';
import { SeedService } from './seed/seed.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ChapterTemplateModel,
      QuestionTemplateModel,
      CaseDefinitionModel,
      IntroQuestionModel,
      IntroChoiceModel,
      PromptTemplateModel,
    ]),
  ],
  providers: [SeedService],
  exports: [SeedService, TypeOrmModule],
})
export class CatalogModule {}
