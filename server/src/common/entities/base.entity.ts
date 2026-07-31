import {
  CreateDateColumn,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

/**
 * 모든 엔티티의 공통 뼈대.
 *
 * ⚠️ PK가 **uuid 문자열**이다. 표준 구조(project-conventions §5.1)의 증분
 *    number가 아니다 — 앱이 모든 `id`를 String으로 다루기로 계약돼 있고
 *    (api-spec §0.1), 자서전은 사용자 데이터라 id로 총량이 새어 나가지
 *    않는 편이 낫다.
 */
export abstract class BaseModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
