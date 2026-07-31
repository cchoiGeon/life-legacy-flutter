import { Column, Entity, JoinColumn, OneToOne, PrimaryColumn } from 'typeorm';

import { AppUserModel } from './app-user.entity';

/**
 * 등록 전에도 행을 만들어 빈 문자열로 둔다 — API가 404 대신 빈 객체를
 * 돌려주기로 했고, 앱이 "없음"과 "못 불러옴"을 구분할 필요가 없다.
 */
@Entity('shipping_address')
export class ShippingAddressModel {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId: string;

  @OneToOne(() => AppUserModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @Column({ type: 'varchar', length: 50, default: '' })
  recipient: string;

  /** 숫자만. 띄우는 건 표시할 때만 */
  @Column({ type: 'varchar', length: 11, default: '' })
  phone: string;

  @Column({ name: 'postal_code', type: 'varchar', length: 10, default: '' })
  postalCode: string;

  @Column({ type: 'varchar', length: 200, default: '' })
  line1: string;

  /** 상세 주소. 비어도 된다 */
  @Column({ type: 'varchar', length: 200, default: '' })
  line2: string;
}
