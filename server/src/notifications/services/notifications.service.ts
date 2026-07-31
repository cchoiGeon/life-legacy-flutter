import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';

import { NotificationResponseDto } from '../dto/response/notification-response.dto';
import { NotificationModel } from '../entities/notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(NotificationModel)
    private readonly notifications: Repository<NotificationModel>,
  ) {}

  async list(userId: string): Promise<NotificationResponseDto[]> {
    const rows = await this.notifications.find({
      where: { user: { id: userId } },
      order: { createdAt: 'DESC' },
    });
    const now = new Date();

    return rows.map((row) => NotificationResponseDto.from(row, now));
  }

  /** 갱신된 목록을 돌려준다 — 앱이 다시 조회하지 않아도 되게 */
  async markAllRead(userId: string): Promise<NotificationResponseDto[]> {
    await this.notifications.update(
      { user: { id: userId }, readAt: IsNull() },
      { readAt: new Date() },
    );

    return await this.list(userId);
  }
}
