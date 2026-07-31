import { Controller, Get, HttpCode, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { NotificationResponseDto } from './dto/response/notification-response.dto';
import { NotificationsService } from './services/notifications.service';

@ApiTags('Notifications API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @ApiOperation({ summary: '알림 목록 (최신순)' })
  @ApiResponse({ status: 200, type: NotificationResponseDto, isArray: true })
  @Get()
  async list(@UserId() userId: string) {
    return { items: await this.notificationsService.list(userId) };
  }

  @ApiOperation({ summary: '모두 읽음' })
  @ApiResponse({ status: 200, type: NotificationResponseDto, isArray: true })
  @HttpCode(200)
  @Post('read-all')
  async markAllRead(@UserId() userId: string) {
    return { items: await this.notificationsService.markAllRead(userId) };
  }
}
