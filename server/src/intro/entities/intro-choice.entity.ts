import { Column, Entity, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { IntroQuestionModel } from './intro-question.entity';

/**
 * 선택지를 표로 두는 이유 — 학력 4지선다의 **원본 값을 보존**하면서
 * "대학 O/X" 판정을 axisValue 한 칸으로 파생시키기 위해서다.
 * 나중에 "고등학교 졸업"과 "중학교 졸업"을 나눠 질문을 주고 싶어지면
 * user_intro_answer에 원본이 남아 있으므로 데이터가 있다.
 */
@Entity('intro_choice')
@Unique('ux_intro_choice_order', ['introQuestion', 'sortOrder'])
export class IntroChoiceModel extends BaseModel {
  @ManyToOne(() => IntroQuestionModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'intro_question_id' })
  introQuestion: IntroQuestionModel;

  @Column({ name: 'sort_order', type: 'smallint' })
  sortOrder: number;

  /** 화면에 뜨는 글자. "대학교 이상" */
  @Column({ type: 'varchar', length: 50 })
  label: string;

  /**
   * 이 선택지가 축을 켜는가. i5의 "대학교 이상"만 true, 나머지 셋은 false.
   * axis=always인 문항이면 null.
   */
  @Column({ name: 'axis_value', type: 'boolean', nullable: true })
  axisValue: boolean | null;
}
