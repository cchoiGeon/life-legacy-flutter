import {
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { LessThanOrEqual, Repository } from 'typeorm';
import { ThrottlerGuard } from '@nestjs/throttler';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { UserId } from './decorator/user.decorator';
import { KakaoLoginDto } from './dto/request/kakao-login.dto';
import { LinkPhoneDto } from './dto/request/link-phone.dto';
import { SaveConsentsDto } from './dto/request/save-consents.dto';
import { RefreshTokenDto } from './dto/request/refresh-token.dto';
import { RequestCodeDto } from './dto/request/request-code.dto';
import { VerifyCodeDto } from './dto/request/verify-code.dto';
import { AuthSessionResponseDto } from './dto/response/auth-session-response.dto';
import { AuthTokensResponseDto } from './dto/response/auth-tokens-response.dto';
import { VerificationChallengeResponseDto } from './dto/response/verification-challenge-response.dto';
import { AccessTokenGuard } from './guard/access-token.guard';
import { AuthService } from './services/auth.service';
import { OctomoService } from './services/octomo.service';
import { SignupService } from './services/signup.service';
import { PhoneLookupDto } from './dto/request/phone-lookup.dto';
import { OctomoChallengeDto } from './dto/request/octomo-challenge.dto';
import { OctomoVerifyDto } from './dto/request/octomo-verify.dto';
import { SignupDto } from './dto/request/signup.dto';
import { CredentialsLoginDto } from './dto/request/credentials-login.dto';
import { SetCredentialsDto } from './dto/request/set-credentials.dto';
import { PhoneLookupResponseDto } from './dto/response/phone-lookup-response.dto';
import { OctomoChallengeResponseDto } from './dto/response/octomo-challenge-response.dto';
import { ConsentDocumentModel } from './entities/consent-document.entity';
import { UserResponseDto } from 'src/users/dto/response/user-response.dto';

@ApiTags('Auth API')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly octomoService: OctomoService,
    private readonly signupService: SignupService,
  ) {}

  // ── 기존 OTP (backward compat) ─────────────────────────

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
    return this.authService.loginWithKakao(dto.kakao_access_token, {
      name: dto.name,
      email: dto.email,
    });
  }

  @ApiOperation({
    summary: '약관 동의 저장',
    description:
      '카카오 등 세션이 이미 발급된 사용자가 필수·선택 약관 동의를 저장한다. 필수 약관이 이미 있으면 앱이 이 화면을 건너뛴다.',
  })
  @ApiResponse({ status: 200, type: AuthSessionResponseDto })
  @ApiBearerAuth('access-token')
  @UseGuards(AccessTokenGuard)
  @HttpCode(200)
  @Post('consents')
  saveConsents(@UserId() userId: string, @Body() dto: SaveConsentsDto) {
    return this.authService.saveConsents(userId, dto.consents);
  }

  @ApiOperation({
    summary: '전화번호 연결',
    description:
      '카카오 등 phone이 없는 계정에 OCTOMO로 인증한 번호를 붙인다. 다른 계정이 쓰는 번호면 409 PHONE_TAKEN.',
  })
  @ApiResponse({ status: 200, type: AuthSessionResponseDto })
  @ApiBearerAuth('access-token')
  @UseGuards(AccessTokenGuard)
  @HttpCode(200)
  @Post('phone/link')
  linkPhone(@UserId() userId: string, @Body() dto: LinkPhoneDto) {
    return this.authService.linkPhone(userId, dto.session_id);
  }

  @ApiOperation({ summary: '아이디·비밀번호 로그인' })
  @ApiResponse({ status: 200, type: AuthSessionResponseDto })
  @UseGuards(ThrottlerGuard)
  @HttpCode(200)
  @Post('login')
  loginWithCredentials(@Body() dto: CredentialsLoginDto) {
    return this.authService.loginWithCredentials(dto.login_id, dto.password);
  }

  @ApiOperation({
    summary: '아이디·비밀번호 만들기',
    description:
      '카카오/전화로 가입한 사용자가 설정에서 아이디·비밀번호를 처음 등록한다',
  })
  @ApiResponse({ status: 200, type: UserResponseDto })
  @ApiBearerAuth('access-token')
  @UseGuards(AccessTokenGuard)
  @HttpCode(200)
  @Post('credentials')
  setCredentials(@UserId() userId: string, @Body() dto: SetCredentialsDto) {
    return this.authService.setCredentials(
      userId,
      dto.login_id,
      dto.password,
    );
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

  // ── OCTOMO 신규 인증 ──────────────────────────────────

  /** api-spec §1.7 — 전화번호 조회 */
  @ApiOperation({
    summary: '전화번호 조회',
    description:
      '가입 여부와 무관하게 항상 같은 응답을 준다. enumeration 방지',
  })
  @ApiResponse({ status: 200, type: PhoneLookupResponseDto })
  @UseGuards(ThrottlerGuard)
  @HttpCode(200)
  @Post('phone/lookup')
  lookupPhone(@Body() _dto: PhoneLookupDto): PhoneLookupResponseDto {
    return { next_step: 'verify' };
  }

  /** api-spec §1.8 — 인증 문자 발급 */
  @ApiOperation({ summary: 'OCTOMO 인증 문자 발급' })
  @ApiResponse({ status: 200, type: OctomoChallengeResponseDto })
  @UseGuards(ThrottlerGuard)
  @HttpCode(200)
  @Post('octomo/challenge')
  async challenge(@Body() dto: OctomoChallengeDto): Promise<OctomoChallengeResponseDto> {
    const result = await this.octomoService.createChallenge(dto.phone, 'login');

    return {
      session_id: result.session.id,
      receiver_number: result.receiverNumber,
      verify_text: result.verifyText,
      expires_in: result.expiresIn,
      poll_interval: result.pollInterval,
    };
  }

  /** api-spec §1.9 — 인증 확인 (폴링) */
  @ApiOperation({ summary: 'OCTOMO 인증 확인 (폴링)' })
  @HttpCode(200)
  @Post('octomo/verify')
  async verify(
    @Body() dto: OctomoVerifyDto,
    @Headers('authorization') authorization?: string,
  ) {
    const result = await this.octomoService.checkVerification(dto.session_id);

    if (result.status === 'pending') {
      return {
        status: 'pending',
        expires_in: result.expiresIn,
      };
    }

    // 카카오 등 phone 연결 모드 — 다른 계정으로 로그인하지 않고 link_ready만 반환.
    if (dto.link) {
      const linkingUserId =
        await this.authService.optionalUserIdFromAuthorization(authorization);
      if (!linkingUserId) {
        throw new ApiException(ERROR_CODE.AUTH.UNAUTHORIZED);
      }
      return {
        status: 'verified',
        account: 'link_ready',
      };
    }

    // verified — 기존 사용자면 session, 신규면 signup_token + required_consents
    const loginResult = await this.authService.loginViaOctomo(dto.session_id);
    if (loginResult) {
      return {
        status: 'verified',
        account: 'existing',
        session: loginResult,
      };
    }

    const consents = await this.signupService.listRequiredConsents();
    return {
      status: 'verified',
      account: 'new',
      signup_token: this.octomoService.toSignupToken(dto.session_id),
      required_consents: consents,
    };
  }

  /** api-spec §1.10 — 회원가입 */
  @ApiOperation({ summary: '회원가입 (이름 + 약관 동의)' })
  @HttpCode(200)
  @Post('signup')
  async signup(@Body() dto: SignupDto) {
    return await this.signupService.signup(
      dto.signup_token,
      dto.name,
      dto.consents,
    );
  }
}

/** api-spec §1.11 — 약관 문서 조회 */
@ApiTags('Consents API')
@Controller('consents')
export class ConsentsController {
  constructor(
    @InjectRepository(ConsentDocumentModel)
    private readonly consentDocumentRepository: Repository<ConsentDocumentModel>,
  ) {}

  @ApiOperation({
    summary: '약관 문서 목록 (현재 시행 중인 버전, 마크다운 본문 포함)',
  })
  @HttpCode(200)
  @Get('documents')
  async getDocuments(
    @Query('consent_only') consentOnly?: string,
  ) {
    const now = new Date();
    const docs = await this.consentDocumentRepository.find({
      where: {
        effectiveAt: LessThanOrEqual(now),
        ...(consentOnly === '1' || consentOnly === 'true'
          ? { isConsentItem: true }
          : {}),
      },
      order: { createdAt: 'ASC' },
    });

    // api-spec §1.11 — key / required / content
    return {
      items: docs.map((d) => this.toDocumentDto(d)),
    };
  }

  @ApiOperation({ summary: '약관 문서 단건 (key로 조회, 본문 포함)' })
  @HttpCode(200)
  @Get('documents/:key')
  async getDocument(@Param('key') key: string) {
    const now = new Date();
    const docs = await this.consentDocumentRepository.find({
      where: {
        consentKey: key,
        effectiveAt: LessThanOrEqual(now),
      },
      order: { effectiveAt: 'DESC', createdAt: 'DESC' },
      take: 1,
    });
    const doc = docs[0];
    if (!doc) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }
    return this.toDocumentDto(doc);
  }

  private toDocumentDto(d: ConsentDocumentModel) {
    return {
      key: d.consentKey,
      version: d.version,
      title: d.title,
      url: d.url || null,
      content: d.content?.trim() ? d.content : null,
      required: d.isRequired,
      consent_item: d.isConsentItem,
      effective_at: d.effectiveAt.toISOString(),
    };
  }
}