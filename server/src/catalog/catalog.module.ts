import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { PromptTemplateModel } from 'src/ai/entities/prompt-template.entity';
import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { BookAccessModule } from 'src/book/book-access.module';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';
import { CaseDefinitionModel } from 'src/intro/entities/case-definition.entity';
import { IntroChoiceModel } from 'src/intro/entities/intro-choice.entity';
import { IntroQuestionModel } from 'src/intro/entities/intro-question.entity';
import { CatalogController } from './catalog.controller';
import { ChapterTemplateModel } from './entities/chapter-template.entity';
import { QuestionTemplateModel } from './entities/question-template.entity';
import { SeedService } from './seed/seed.service';
import { CatalogService } from './services/catalog.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ChapterTemplateModel,
      QuestionTemplateModel,
      CaseDefinitionModel,
      IntroQuestionModel,
      IntroChoiceModel,
      PromptTemplateModel,
      UserChapterModel,
    ]),
    AuthGuardModule,
    BookAccessModule,
  ],
  controllers: [CatalogController],
  providers: [SeedService, CatalogService],
  exports: [SeedService, TypeOrmModule, CatalogService],
})
export class CatalogModule {}
