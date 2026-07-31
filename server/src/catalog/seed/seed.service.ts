import { Injectable, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';

import { PromptTemplateModel } from 'src/ai/entities/prompt-template.entity';
import { PROMPT_SEED } from 'src/ai/seed/prompt.seed';
import { CaseDefinitionModel } from 'src/intro/entities/case-definition.entity';
import { IntroChoiceModel } from 'src/intro/entities/intro-choice.entity';
import { IntroQuestionModel } from 'src/intro/entities/intro-question.entity';
import { CASE_SEED } from 'src/intro/seed/case.seed';
import { INTRO_QUESTION_SEED } from 'src/intro/seed/intro-question.seed';
import { ChapterTemplateModel } from '../entities/chapter-template.entity';
import { QuestionTemplateModel } from '../entities/question-template.entity';
import { CHAPTER_SEED } from './catalog.seed';

/**
 * 전 사용자 공용 카탈로그를 채운다.
 *
 * **여러 번 돌려도 같은 결과가 되게(멱등)** 만들었다. 시드는 배포마다
 * 다시 도는 일이 흔한데, 그때마다 대주제가 두 벌씩 생기면 목차 생성이
 * 통째로 어긋난다. 자연키(code / caseKey / key)로 찾아 없을 때만 넣는다.
 */
@Injectable()
export class SeedService {
  private readonly logger = new Logger('Seed');

  constructor(private readonly dataSource: DataSource) {}

  async run(): Promise<void> {
    await this.seedChapters();
    await this.seedCases();
    await this.seedIntroQuestions();
    await this.seedPrompts();
  }

  private async seedChapters(): Promise<void> {
    const chapters = this.dataSource.getRepository(ChapterTemplateModel);
    const questions = this.dataSource.getRepository(QuestionTemplateModel);

    for (const [index, seed] of CHAPTER_SEED.entries()) {
      let chapter = await chapters.findOne({ where: { code: seed.code } });
      if (!chapter) {
        chapter = await chapters.save(
          chapters.create({
            code: seed.code,
            title: seed.title,
            sortOrder: index + 1,
            condition: seed.condition,
          }),
        );
      }

      for (const [order, text] of seed.questions.entries()) {
        const exists = await questions.findOne({
          where: { chapterTemplate: { id: chapter.id }, sortOrder: order + 1 },
        });
        if (exists) {
          continue;
        }

        await questions.save(
          questions.create({
            chapterTemplate: chapter,
            sortOrder: order + 1,
            text,
          }),
        );
      }
    }

    this.logger.log(`대주제 ${CHAPTER_SEED.length}개 확인`);
  }

  private async seedCases(): Promise<void> {
    const cases = this.dataSource.getRepository(CaseDefinitionModel);

    for (const seed of CASE_SEED) {
      const exists = await cases.findOne({ where: { caseKey: seed.caseKey } });
      if (exists) {
        continue;
      }

      await cases.save(cases.create(seed));
    }

    this.logger.log(`케이스 ${CASE_SEED.length}종 확인`);
  }

  private async seedIntroQuestions(): Promise<void> {
    const questions = this.dataSource.getRepository(IntroQuestionModel);
    const choices = this.dataSource.getRepository(IntroChoiceModel);

    for (const [index, seed] of INTRO_QUESTION_SEED.entries()) {
      let question = await questions.findOne({ where: { code: seed.code } });
      if (!question) {
        question = await questions.save(
          questions.create({
            code: seed.code,
            sortOrder: index + 1,
            text: seed.text,
            subtitle: seed.subtitle,
            hint: seed.hint,
            axis: seed.axis,
          }),
        );
      }

      for (const [order, [label, axisValue]] of seed.choices.entries()) {
        const exists = await choices.findOne({
          where: { introQuestion: { id: question.id }, sortOrder: order + 1 },
        });
        if (exists) {
          continue;
        }

        await choices.save(
          choices.create({
            introQuestion: question,
            sortOrder: order + 1,
            label,
            axisValue,
          }),
        );
      }
    }

    this.logger.log(`자기소개 ${INTRO_QUESTION_SEED.length}문항 확인`);
  }

  private async seedPrompts(): Promise<void> {
    const prompts = this.dataSource.getRepository(PromptTemplateModel);

    for (const seed of PROMPT_SEED) {
      const exists = await prompts.findOne({ where: { key: seed.key } });
      if (exists) {
        continue;
      }

      await prompts.save(prompts.create(seed));
    }

    this.logger.log(`프롬프트 ${PROMPT_SEED.length}종 확인`);
  }
}
