import {
  Body,
  Controller,
  Delete,
  HttpCode,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { RegisterDevicePushTokenDto } from './dto/request/register-device-push-token.dto';
import { DevicePushTokensService } from './services/device-push-tokens.service';

@ApiTags('Device Push Tokens API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('device-push-tokens')
export class DevicePushTokensController {
  constructor(private readonly devicePushTokens: DevicePushTokensService) {}

  @ApiOperation({ summary: '단말 FCM 토큰 등록/갱신 (upsert)' })
  @ApiResponse({ status: 204 })
  @HttpCode(204)
  @Post()
  async register(
    @UserId() userId: string,
    @Body() dto: RegisterDevicePushTokenDto,
  ): Promise<void> {
    await this.devicePushTokens.register(userId, dto);
  }

  @ApiOperation({ summary: '단말 FCM 토큰 폐기' })
  @ApiResponse({ status: 204 })
  @HttpCode(204)
  @Delete(':token')
  async revoke(
    @UserId() userId: string,
    @Param('token') token: string,
  ): Promise<void> {
    await this.devicePushTokens.revoke(userId, decodeURIComponent(token));
  }
}
