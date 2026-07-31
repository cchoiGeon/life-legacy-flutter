import { Body, Controller, Get, Patch, Put, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { AppSettingsDto, ShippingAddressDto } from './dto/settings.dto';
import { SettingsService } from './services/settings.service';

@ApiTags('Settings API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller()
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @ApiOperation({ summary: '앱 설정' })
  @ApiResponse({ status: 200, type: AppSettingsDto })
  @Get('settings')
  getSettings(@UserId() userId: string) {
    return this.settingsService.getSettings(userId);
  }

  @ApiOperation({ summary: '앱 설정 변경' })
  @ApiResponse({ status: 200, type: AppSettingsDto })
  @Patch('settings')
  updateSettings(@UserId() userId: string, @Body() dto: AppSettingsDto) {
    return this.settingsService.updateSettings(userId, dto);
  }

  @ApiOperation({ summary: '인쇄본 배송지' })
  @ApiResponse({ status: 200, type: ShippingAddressDto })
  @Get('shipping-address')
  getAddress(@UserId() userId: string) {
    return this.settingsService.getAddress(userId);
  }

  @ApiOperation({ summary: '인쇄본 배송지 저장' })
  @ApiResponse({ status: 200, type: ShippingAddressDto })
  @Put('shipping-address')
  updateAddress(@UserId() userId: string, @Body() dto: ShippingAddressDto) {
    return this.settingsService.updateAddress(userId, dto);
  }
}
