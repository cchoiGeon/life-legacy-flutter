import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';

import { CaseDefinitionModel } from '../entities/case-definition.entity';
import { IntroChoiceModel } from '../entities/intro-choice.entity';
import { IntroQuestionModel } from '../entities/intro-question.entity';
import { UserIntroAnswerModel } from '../entities/user-intro-answer.entity';
import { UserProfileModel } from '../entities/user-profile.entity';
import { WritingPlanModel } from '../entities/writing-plan.entity';
import { IntroChoiceResponseDto } from '../dto/response/intro-question-response.dto';

@Injectable()
export class IntroRepository {
  constructor(
    @InjectRepository(IntroQuestionModel)
    private readonly questions: Repository<IntroQuestionModel>,
    @InjectRepository(IntroChoiceModel)
    private readonly choices: Repository<IntroChoiceModel>,
    @InjectRepository(UserIntroAnswerModel)
    private readonly answers: Repository<UserIntroAnswerModel>,
    @InjectRepository(CaseDefinitionModel)
    private readonly cases: Repository<CaseDefinitionModel>,
    @InjectRepository(UserProfileModel)
    private readonly profiles: Repository<UserProfileModel>,
    @InjectRepository(WritingPlanModel)
    private readonly writingPlans: Repository<WritingPlanModel>,
  ) {}

  async findActiveQuestions(): Promise<IntroQuestionModel[]> {
    return await this.questions.find({
      where: { isActive: true },
      order: { sortOrder: 'ASC' },
    });
  }

  async findChoiceTreeByQuestionIds(
    questionIds: string[],
  ): Promise<Map<string, IntroChoiceResponseDto[]>> {
    const result = new Map<string, IntroChoiceResponseDto[]>();
    if (questionIds.length === 0) return result;

    const all = await this.choices.find({
      where: { introQuestion: { id: In(questionIds) } },
      relations: { introQuestion: true, parentChoice: true },
      order: { sortOrder: 'ASC' },
    });

    const tops = all.filter((c) => !c.parentChoice);
    const details = all.filter((c) => c.parentChoice);

    for (const qid of questionIds) {
      const topForQ = tops.filter((c) => c.introQuestion.id === qid);
      result.set(
        qid,
        topForQ.map((c) => {
          const kids = details.filter((d) => d.parentChoice?.id === c.id);
          const dto: IntroChoiceResponseDto = {
            id: c.id,
            label: c.label,
          };
          if (kids.length > 0) {
            dto.details = kids.map((k) => ({ id: k.id, label: k.label }));
          }
          return dto;
        }),
      );
    }

    return result;
  }

  async findAnswersByUser(userId: string): Promise<UserIntroAnswerModel[]> {
    return await this.answers.find({
      where: { user: { id: userId } },
      relations: { introQuestion: true },
      order: { introQuestion: { sortOrder: 'ASC' } },
    });
  }

  async findWritingPlan(userId: string): Promise<WritingPlanModel | null> {
    return await this.writingPlans.findOne({ where: { userId } });
  }

  async upsertWritingPlan(
    plan: Partial<WritingPlanModel> & { userId: string },
  ): Promise<WritingPlanModel> {
    await this.writingPlans.save(this.writingPlans.create(plan));
    return (await this.findWritingPlan(plan.userId))!;
  }
}
