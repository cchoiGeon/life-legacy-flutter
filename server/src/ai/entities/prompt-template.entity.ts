import { Column, Entity } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';

/** 프롬프트를 코드에 박지 않는다. 문구 조정이 배포 없이 되어야 한다 */
@Entity('prompt_template')
export class PromptTemplateModel extends BaseModel {
  /** followup | polish */
  @Column({ type: 'varchar', length: 30, unique: true })
  key: string;

  @Column({ type: 'varchar', length: 100 })
  title: string;

  /** {{chapter_title}} {{question}} {{answer}} 같은 플레이스홀더 */
  @Column({ type: 'text' })
  body: string;

  @Column({ type: 'int', default: 1 })
  version: number;

  @Column({ name: 'updated_by', type: 'varchar', length: 100, nullable: true })
  updatedBy: string | null;
}
