import {
  Controller,
  Get,
  Header,
  HttpCode,
  Post,
  Res,
  StreamableFile,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import type { Response } from 'express';
import { memoryStorage } from 'multer';

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

  @ApiOperation({ summary: '프로필 사진 업로드' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        avatar: { type: 'string', format: 'binary' },
      },
      required: ['avatar'],
    },
  })
  @ApiResponse({ status: 200, type: UserResponseDto })
  @HttpCode(200)
  @Post('me/avatar')
  @UseInterceptors(
    FileInterceptor('avatar', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  uploadAvatar(
    @UserId() userId: string,
    @UploadedFile() file: Express.Multer.File | undefined,
  ) {
    return this.usersService.uploadAvatar(userId, file!);
  }

  @ApiOperation({ summary: '프로필 사진 조회' })
  @Get('me/avatar')
  async getAvatar(
    @UserId() userId: string,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    const { file, contentType } =
      await this.usersService.getAvatarStream(userId);
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'private, max-age=3600');
    return file;
  }
}
