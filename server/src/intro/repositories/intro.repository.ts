import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CaseDefinitionModel } from '../entities/case-definition.entity';
import { IntroChoiceModel } from '../entities/intro-choice.entity';
import { IntroQuestionModel } from '../entities/intro-question.entity';
import { UserIntroAnswerModel } from '../entities/user-intro-answer.entity';
import { UserProfileModel } from '../entities/user-profile.entity';

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
  ) {}

  async findActiveQuestions(): Promise<IntroQuestionModel[]> {
    return await this.questions.find({
      where: { isActive: true },
      order: { sortOrder: 'ASC' },
    });
  }

  /**
   * 질문 id → 선택지 라벨.
   *
   * ⚠️ 엔티티만 돌려주면 FK(intro_question_id)가 실려 오지 않아 어느 질문의
   *    선택지인지 알 수 없다. 실제로 그 탓에 선택지가 전부 빈 배열로 나가서
   *    앱이 학력 4지선다를 텍스트 입력으로 그렸다. id를 명시적으로 뽑는다.
   */
  async findChoiceLabelsByQuestionIds(
    questionIds: string[],
  ): Promise<{ questionId: string; label: string }[]> {
    if (questionIds.length === 0) {
      return [];
    }

    return await this.choices
      .createQueryBuilder('c')
      .select('c.intro_question_id', 'questionId')
      .addSelect('c.label', 'label')
      .where('c.intro_question_id IN (:...ids)', { ids: questionIds })
      .orderBy('c.sort_order', 'ASC')
      .getRawMany<{ questionId: string; label: string }>();
  }

  async findCaseByAxes(
    hasCollege: boolean,
    hasMarriage: boolean,
    hasChildren: boolean,
  ): Promise<CaseDefinitionModel | null> {
    return await this.cases.findOne({
      where: { hasCollege, hasMarriage, hasChildren },
    });
  }

  async findAnswersByUser(userId: string): Promise<UserIntroAnswerModel[]> {
    return await this.answers.find({
      where: { user: { id: userId } },
      relations: { introQuestion: true },
      order: { introQuestion: { sortOrder: 'ASC' } },
    });
  }

  async findProfile(userId: string): Promise<UserProfileModel | null> {
    return await this.profiles.findOne({
      where: { userId },
      relations: { case: true },
    });
  }
}
