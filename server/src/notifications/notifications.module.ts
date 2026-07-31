import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { NotificationModel } from './entities/notification.entity';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './services/notifications.service';

@Module({
  imports: [TypeOrmModule.forFeature([NotificationModel]), AuthGuardModule],
  controllers: [NotificationsController],
  providers: [NotificationsService],
})
export class NotificationsModule {}
