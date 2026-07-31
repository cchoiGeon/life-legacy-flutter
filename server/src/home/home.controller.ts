import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { HomeResponseDto } from './dto/response/home-response.dto';
import { HomeService } from './services/home.service';

@ApiTags('Home API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('home')
export class HomeController {
  constructor(private readonly homeService: HomeService) {}

  @ApiOperation({ summary: '홈 요약' })
  @ApiResponse({ status: 200, type: HomeResponseDto })
  @Get()
  getHome(@UserId() userId: string) {
    return this.homeService.getHome(userId);
  }
}
