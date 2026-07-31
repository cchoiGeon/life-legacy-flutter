import { Controller, Get, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { UserResponseDto } from './dto/response/user-response.dto';
import { UsersService } from './services/users.service';

@ApiTags('Users API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @ApiOperation({ summary: '내 정보' })
  @ApiResponse({ status: 200, type: UserResponseDto })
  @Get('me')
  me(@UserId() userId: string) {
    return this.usersService.getMe(userId);
  }
}
