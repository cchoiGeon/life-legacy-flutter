import { Column, Entity, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';

/**
 * 8종 = 2(대학) x 2(결혼) x 2(자녀). 세 축이 서로 독립이다.
 *
 * 축 조합에 unique를 걸어 중복·누락 케이스가 들어오지 못하게 한다.
 * **케이스별 목차 목록을 여기 나열하지 않는다** — chapter_template.condition
 * 에서 파생된다.
 */
@Entity('case_definition')
@Unique('ux_case_axes', ['hasCollege', 'hasMarriage', 'hasChildren'])
export class CaseDefinitionModel extends BaseModel {
  @Column({ name: 'case_key', type: 'varchar', length: 60, unique: true })
  caseKey: string;

  @Column({ type: 'varchar', length: 100 })
  title: string;

  @Column({ type: 'varchar', length: 300 })
  description: string;

  @Column({ name: 'has_college', type: 'boolean' })
  hasCollege: boolean;

  @Column({ name: 'has_marriage', type: 'boolean' })
  hasMarriage: boolean;

  @Column({ name: 'has_children', type: 'boolean' })
  hasChildren: boolean;

  @Column({ name: 'sort_order', type: 'smallint' })
  sortOrder: number;
}
