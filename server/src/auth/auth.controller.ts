import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { ThrottlerGuard } from '@nestjs/throttler';

import { UserId } from './decorator/user.decorator';
import { KakaoLoginDto } from './dto/request/kakao-login.dto';
import { RefreshTokenDto } from './dto/request/refresh-token.dto';
import { RequestCodeDto } from './dto/request/request-code.dto';
import { VerifyCodeDto } from './dto/request/verify-code.dto';
import { AuthSessionResponseDto } from './dto/response/auth-session-response.dto';
import { AuthTokensResponseDto } from './dto/response/auth-tokens-response.dto';
import { VerificationChallengeResponseDto } from './dto/response/verification-challenge-response.dto';
import { AccessTokenGuard } from './guard/access-token.guard';
import { AuthService } from './services/auth.service';

@ApiTags('Auth API')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @ApiOperation({ summary: '인증번호 발송' })
  @ApiResponse({ status: 200, type: VerificationChallengeResponseDto })
  @UseGuards(ThrottlerGuard)
  @HttpCode(200)
  @Post('phone/code')
  requestCode(@Body() dto: RequestCodeDto) {
    return this.authService.requestVerificationCode(dto.phone);
  }

  @ApiOperation({ summary: '인증번호 확인 (가입/로그인 겸용)' })
  @ApiResponse({ status: 200, type: AuthSessionResponseDto })
  @UseGuards(ThrottlerGuard)
  @HttpCode(200)
  @Post('phone/verify')
  verifyCode(@Body() dto: VerifyCodeDto) {
    return this.authService.verifyCode(dto.phone, dto.code);
  }

  @ApiOperation({ summary: '카카오로 시작하기' })
  @ApiResponse({ status: 200, type: AuthSessionResponseDto })
  @HttpCode(200)
  @Post('kakao')
  loginWithKakao(@Body() dto: KakaoLoginDto) {
    return this.authService.loginWithKakao(dto.kakao_access_token);
  }

  @ApiOperation({ summary: '토큰 갱신' })
  @ApiResponse({ status: 200, type: AuthTokensResponseDto })
  @HttpCode(200)
  @Post('refresh')
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refresh(dto.refresh_token);
  }

  @ApiOperation({ summary: '로그아웃' })
  @ApiResponse({ status: 204 })
  @ApiBearerAuth('access-token')
  @UseGuards(AccessTokenGuard)
  @HttpCode(204)
  @Post('logout')
  logout(@UserId() userId: string) {
    return this.authService.logout(userId);
  }
}
