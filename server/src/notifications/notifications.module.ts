import { Module, forwardRef } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { BookAccessModule } from 'src/book/book-access.module';
import { ChaptersModule } from 'src/chapters/chapters.module';
import { WritingPlanModel } from 'src/intro/entities/writing-plan.entity';
import { UserSettingModel } from 'src/users/entities/user-setting.entity';
import { DevicePushTokensModule } from './device-push-tokens.module';
import { NotificationModel } from './entities/notification.entity';
import { NotificationsController } from './notifications.controller';
import { DailyQuestionSchedulerService } from './services/daily-question-scheduler.service';
import { NotificationsService } from './services/notifications.service';
import { PushSenderService } from './services/push-sender.service';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    TypeOrmModule.forFeature([
      NotificationModel,
      UserSettingModel,
      WritingPlanModel,
    ]),
    AuthGuardModule,
    BookAccessModule,
    DevicePushTokensModule,
    forwardRef(() => ChaptersModule),
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    PushSenderService,
    DailyQuestionSchedulerService,
  ],
  exports: [NotificationsService, PushSenderService, DevicePushTokensModule],
})
export class NotificationsModule {}
