# NestJS 백엔드 프로젝트 표준 (구조 · 개발 방법)

이 문서는 `spincell-server`에서 실제로 사용 중인 디렉터리 구조와 개발 규칙을 정리한 것이다.
**새 프로젝트를 동일한 구조로 시작할 때 이 문서 하나만 보고 세팅할 수 있도록** 작성했다.

- 아키텍처: **DDD 도메인 모듈 + 레이어드(Controller → Service → Repository)**
- 스택: NestJS 11 / TypeScript 5 / TypeORM 0.3 (PostgreSQL) / Redis(ioredis) / Socket.IO / Swagger / Jest
- 런타임: Node 24.x, npm 11+
- 배포: GitHub Actions → S3 → AWS CodeDeploy → EC2(pm2)

---

## 1. 기술 스택 & 의존성 베이스라인

새 프로젝트에서 기본으로 깔고 가는 패키지 세트다.

| 영역 | 패키지 |
|---|---|
| 코어 | `@nestjs/common` `@nestjs/core` `@nestjs/platform-express` `reflect-metadata` `rxjs` |
| 설정 | `@nestjs/config` |
| DB | `@nestjs/typeorm` `typeorm` `pg` |
| 검증/변환 | `class-validator` `class-transformer` |
| 문서화 | `@nestjs/swagger` `js-yaml` `express-basic-auth` |
| 인증 | `@nestjs/jwt` `bcrypt` |
| 캐시/큐 | `ioredis` |
| 실시간 | `@nestjs/websockets` `@nestjs/platform-socket.io` `socket.io` `@socket.io/redis-adapter` |
| 스케줄 | `@nestjs/schedule` |
| 레이트리밋 | `@nestjs/throttler` |
| 파일 | `multer` `@aws-sdk/client-s3` |
| 비밀관리 | `@aws-sdk/client-ssm` |
| 유틸 | `date-fns` `es-toolkit` `uuid` |
| 개발 | `@nestjs/cli` `jest` `ts-jest` `supertest` `eslint` `typescript-eslint` `prettier` |

`package.json` 스크립트 표준:

```jsonc
{
  "scripts": {
    "build": "rm -rf dist && nest build",
    "start:local": "NODE_ENV=local nest start --watch",
    "start:dev": "NODE_ENV=development nest start --watch",
    "start:production": "NODE_ENV=production node dist/main",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "format": "prettier --write \"src/**/*.ts\" \"test/**/*.ts\"",
    "test": "jest",
    "test:cov": "jest --coverage"
  }
}
```

Jest 설정은 `package.json`에 인라인으로 두고, **테스트 파일은 소스 옆에 둔다**(`rootDir: "src"`, `testRegex: ".*\\.spec\\.ts$"`).

```jsonc
"jest": {
  "moduleFileExtensions": ["js", "json", "ts"],
  "rootDir": "src",
  "testRegex": ".*\\.spec\\.ts$",
  "transform": { "^.+\\.(t|j)s$": "ts-jest" },
  "moduleNameMapper": { "^src/(.*)$": "<rootDir>/$1" },
  "coverageDirectory": "../coverage",
  "testEnvironment": "node"
}
```

---

## 2. 루트 디렉터리 구조

```
project-root/
├── .github/
│   ├── ISSUE_TEMPLATE/          # issue-bug / issue-feature / issue-refactor / issue-documentation (yml)
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/deploy.yml     # prd 브랜치 push → 배포
├── .cursor/
│   ├── rules/                   # 항상 적용되는 코딩 규칙 (.mdc)
│   └── skills/                  # 반복 작업 스킬 (커밋 컨벤션, ERD 자동화 등)
├── .claude/
│   ├── commands/                # 슬래시 커맨드 (예: /erd)
│   └── settings.local.json
├── docs/
│   ├── api/                     # 프론트 연동용 API 가이드
│   ├── domain/                  # 도메인별 분석/설계 문서 (+ README 색인)
│   └── superpowers/
│       ├── specs/               # 설계 문서 (YYYY-MM-DD-<기능>-design.md)
│       ├── plans/               # 구현 계획 (YYYY-MM-DD-<기능>.md)
│       └── reports/             # 구현 결과 리포트
├── scripts/                     # CodeDeploy 훅 스크립트 (install/start/validate)
├── src/                         # 애플리케이션 코드 (3장)
├── appspec.yml                  # CodeDeploy 명세
├── nest-cli.json
├── tsconfig.json / tsconfig.build.json
├── eslint.config.mjs
├── .prettierrc
├── .nvmrc
├── .env.local / .env.development     # (git ignore, 운영값은 SSM)
└── README.md
```

**원칙**

- 루트에는 설정 파일만. 코드는 전부 `src/`.
- 문서는 전부 `docs/` 아래, 목적별로 `api` / `domain` / `superpowers`로 분리.
- AI 도구 규칙(`.cursor/rules`, `.claude/commands`)도 저장소에 커밋해서 팀 전체가 동일한 규칙을 공유한다.

---

## 3. `src/` 구조 — 도메인 모듈 단위

```
src/
├── main.ts                  # 부트스트랩 (전역 파이프/필터/인터셉터/Swagger)
├── app.module.ts            # 루트 모듈 (ConfigModule, TypeOrmModule, 도메인 모듈 등록)
├── app.controller.ts        # /health 등 최소 라우트
├── config/
│   └── ssm.config.ts        # 운영 환경 비밀값 주입
├── common/                  # 도메인에 속하지 않는 공용 인프라 (5장)
├── users/                   # ← 도메인 모듈
├── auth/
├── clusters/
├── venues/
└── ...
```

### 3.1 도메인 모듈 표준 레이아웃

각 도메인은 **하나의 상위 폴더 = 하나의 NestJS 모듈**이다.

```
<domain>/
├── <domain>.module.ts        # 모듈 정의
├── <domain>.controller.ts    # 엔드포인트가 많으면 controllers/ 디렉터리로 승격
├── <domain>.gateway.ts       # (선택) WebSocket
├── services/
│   ├── <domain>.service.ts               # 핵심 비즈니스 로직
│   ├── <domain>-<sub>.service.ts         # 하위 관심사 분리 (예: venue-comment.service.ts)
│   ├── <domain>-transaction.service.ts   # 트랜잭션 전용
│   └── <domain>.service.spec.ts          # 테스트는 소스 옆에
├── repositories/
│   └── <entity>.repository.ts            # 엔티티(역할) 단위로 분리
├── entities/
│   └── <entity>.entity.ts
├── dto/
│   ├── request/*.dto.ts
│   └── response/*-response.dto.ts
├── const/                    # 도메인 전용 enum/상수/타입/유틸/정책
├── decorator/                # (선택) 도메인 전용 데코레이터
├── guard/                    # (선택) 도메인 전용 가드
├── filters/                  # (선택)
└── types/                    # (선택) 서비스 입력용 내부 타입
```

실제 예시 (`src/venues/`):

```
venues/
├── venues.module.ts
├── venues.controller.ts
├── services/       venues.service.ts, venue-comment.service.ts,
│                   venue-invitation.service.ts, venue-transaction.service.ts
├── repositories/   venues.repository.ts, venue-bookmark.repository.ts,
│                   venue-comment.repository.ts, venue-like.repository.ts, ...
├── entities/       venues.entity.ts, venue-bookmark.entity.ts, venue-comments.entity.ts, ...
├── dto/request/    create-venue-comment.dto.ts, get-venue.dto.ts, ...
├── dto/response/   get-venue-detail-response.dto.ts, get-all-venue-response.dto.ts, ...
├── const/          location-category.enum.ts, venue-invitation-status.const.ts
└── types/          create-venue-input.ts
```

### 3.2 도메인 경계 잡는 법

- **엔티티가 같은 애그리게이트에 속하면 같은 도메인 폴더**에 둔다.
  `venue-bookmark`, `venue-like`, `venue-comment`는 전부 `venues/`.
- 여러 도메인이 공유하는 조회용 마스터 데이터는 작은 지원 도메인으로 뺀다 (`songs`, `genres`, `tags`, `geocoding`).
- 외부 시스템 연동은 별도 도메인 (`slack`, `notifications/providers`).
- 관리자 기능은 도메인마다 흩뿌리지 않고 **`admin/` 단일 모듈**로 모은다 (별도 인증 체계, 별도 가드/인터셉터를 쓰기 때문).

---

## 4. 레이어드 아키텍처 규칙

**Controller → Service → Repository** 흐름을 반드시 지킨다.

### 4.1 Controller

책임: HTTP 요청/응답 처리, Swagger 문서화, 서비스 호출. **비즈니스 로직 금지.**

```ts
@ApiTags('Venues API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('venues')
export class VenuesController {
  constructor(
    private readonly venuesService: VenuesService,
    private readonly venueCommentService: VenueCommentService,
  ) {}

  @ApiOperation({ summary: 'Venue 상세 조회' })
  @ApiResponse({
    status: 200,
    description: '요청이 성공적으로 처리되었습니다.',
    type: GetVenueDetailResponseDto,
  })
  @Get(':id')
  getVenueDetail(
    @Param('id', ParseIntPipe) venueId: number,
    @User() user: UserModel,
  ) {
    return this.venuesService.getVenueDetail(venueId, user.id);
  }
}
```

- 경로 파라미터는 `ParseIntPipe` 등 파이프로 1차 검증.
- 인증 사용자는 커스텀 데코레이터(`@User()`)로 주입.
- 컨트롤러 메서드는 `return service.xxx()` 한 줄이 이상적.

### 4.2 Service

책임: 도메인 비즈니스 로직, 다른 도메인 서비스와의 협력, 트랜잭션 서비스 호출.

- 도메인 규칙·검증·예외 발생은 전부 여기.
- 도메인 간 호출은 **서비스 ↔ 서비스**로만. 순환이 필요하면 `forwardRef()`.
- 하나의 서비스가 비대해지면 관심사별로 쪼갠다 (`venue-comment.service.ts`, `venue-invitation.service.ts`).

### 4.3 Repository

책임: **순수 데이터 접근**. 비즈니스 규칙 금지.

```ts
export class VenueBookmarkRepository {
  constructor(
    @InjectRepository(VenueBookmarkModel)
    private readonly venueBookmarkRepository: Repository<VenueBookmarkModel>,
  ) {}

  async findByUserIdAndVenueId(venueId: number, userId: number) {
    return await this.venueBookmarkRepository.findOne({
      where: { venue: { id: venueId }, user: { id: userId } },
    });
  }

  async existsVenueBookmark(venueId: number, userId: number) {
    return await this.venueBookmarkRepository.exists({
      where: { venue: { id: venueId }, user: { id: userId } },
    });
  }

  async remove(venueBookmark: VenueBookmarkModel) {
    return await this.venueBookmarkRepository.remove(venueBookmark);
  }
}
```

- 반드시 `@InjectRepository(Entity)` 주입.
- 엔티티(역할)마다 리포지토리를 나눈다. 한 도메인에 리포지토리 10개가 나와도 정상.
- **리포지토리는 다른 도메인의 리포지토리/서비스에 의존하지 않는다.**

### 4.4 Transaction Service

여러 엔티티를 원자적으로 다뤄야 하면 `<domain>-transaction.service.ts`를 따로 둔다.

```ts
@Injectable()
export class VenueTransactionService {
  constructor(private readonly dataSource: DataSource) {}

  async acceptVenueInvitation(userId: number, invitationId: number) {
    return await this.dataSource.transaction(async (manager) => {
      // manager.getRepository(...) 로 트랜잭션 컨텍스트 내에서 처리
      // 동시성 가드는 조건부 UPDATE + affected 검사로 원자성 확보
    });
  }
}
```

동시성이 걸리는 상태 전이는 "조회 후 저장"이 아니라 **조건부 UPDATE + `affected === 0` 검사**로 처리한다.

### 4.5 Module

```ts
@Module({
  imports: [
    TypeOrmModule.forFeature([VenueModel, VenueBookmarkModel /* ... */]),
    AuthModule,
    NotificationsModule,
    forwardRef(() => UsersModule),   // 순환 참조일 때만
  ],
  controllers: [VenuesController],
  providers: [
    VenuesService, VenueCommentService, VenueTransactionService,
    VenuesRepository, VenueBookmarkRepository, /* ... */
  ],
  exports: [VenuesService],          // 외부에 노출할 서비스만
})
export class VenuesModule {}
```

---

## 5. `common/` — 공용 인프라

```
common/
├── common.module.ts / common.controller.ts / common.service.ts   # 이미지 업로드 등 공용 API
├── adapters/       redis-io.adapter.ts        # Socket.IO 멀티 인스턴스 어댑터
├── config/         swagger.config.ts
├── const/          path.const.ts, image-upload.const.ts
├── dto/response/   공용 응답 DTO
├── entities/       base.entity.ts
├── exception/      api.exception.ts, error-code.const.ts
├── filters/        http-exception.filter.ts, ws-exception.filter.ts
├── interceptors/   response.interceptor.ts
├── redis/          redis.module.ts, redis.service.ts, redis.constants.ts
├── schedulers/     *.scheduler.ts             # @Cron 작업
├── utils/          범용 유틸 (+ *.spec.ts)
└── validators/     커스텀 class-validator
```

판단 기준: **두 개 이상의 도메인이 쓰면 `common/`, 하나의 도메인만 쓰면 그 도메인의 `const/`.**

### 5.1 BaseModel

모든 엔티티는 이걸 상속한다.

```ts
export abstract class BaseModel {
  @PrimaryGeneratedColumn()
  id: number;

  @UpdateDateColumn()
  updatedAt: Date;

  @CreateDateColumn()
  createdAt: Date;
}
```

엔티티 규칙:

- 클래스명 `XxxModel`, 파일명 `xxx.entity.ts`, 테이블명 `@Entity('xxx_model')`.
- 관계는 `@ManyToOne(() => X, { onDelete: 'CASCADE' })` + `@JoinColumn()`.
- 조합 유니크는 `@Unique(['a', 'b'])`.
- 소프트 삭제가 필요하면 `@DeleteDateColumn()`.

### 5.2 에러 코드 & ApiException

도메인별 에러 코드를 한 파일에 모은다.

```ts
export type ErrorCodeValue = { status: number; code: string; message: string };

export const ERROR_CODE = {
  USER: {
    WITHDRAWAL_USER: { status: 409, code: 'USER_001', message: '탈퇴한 회원입니다.' },
    NOT_FOUND_USER:  { status: 404, code: 'USER_002', message: '사용자를 찾을 수 없습니다.' },
  },
  CLUSTER: {
    DUPLICATE_SONG_REQUEST: { status: 409, code: 'CLUSTER_001', message: '이미 신청된 곡입니다.' },
  },
} as const;
```

```ts
export class ApiException extends HttpException {
  readonly errorCode: string;
  constructor(errorCode: ErrorCodeValue, customMessage?: string) {
    super({ statusCode: errorCode.status, code: errorCode.code,
            message: customMessage ?? errorCode.message }, errorCode.status);
    this.errorCode = errorCode.code;
  }
}
```

- 클라이언트가 **분기 처리해야 하는 에러**는 `ApiException` + 에러 코드.
- 그 외 단순 실패는 Nest 기본 예외(`NotFoundException` 등)로 충분하다.

### 5.3 응답 규약

`ResponseInterceptor`가 모든 성공 응답을 감싼다.

```jsonc
// 성공
{ "statusCode": 200, "message": "요청이 성공적으로 처리되었습니다.", "data": { ... } }

// 실패 (HttpExceptionFilter)
{ "statusCode": 404, "message": "사용자를 찾을 수 없습니다.",
  "data": { "code": "USER_002", "message": "사용자를 찾을 수 없습니다." } }
```

`HttpExceptionFilter`는 `@Catch()`(전역)로 잡고 **에러 1건 = 로그 1줄**로 남긴다.
`method url → status | detail | body` 형식이며, 5xx만 스택을 붙이고 4xx는 `warn` 한 줄로 남겨 노이즈를 줄인다.

---

## 6. 부트스트랩 (`main.ts`) 표준

순서가 중요하다. 아래 순서를 그대로 가져간다.

```ts
async function bootstrap() {
  const logger = new Logger('Bootstrap');
  try {
    // 1. 운영 환경이면 ConfigModule이 읽기 전에 SSM 값을 process.env에 주입
    await injectSsmEnvIfProd();

    const app = await NestFactory.create(AppModule, {
      logger: ['error', 'warn', 'log', 'debug', 'verbose'],
    });

    // 2. WebSocket을 쓴다면 Redis 어댑터 (멀티 인스턴스 룸 동기화)
    const redisIoAdapter = new RedisIoAdapter(app);
    redisIoAdapter.connectToRedis();
    app.useWebSocketAdapter(redisIoAdapter);

    // 3. 전역 예외 필터
    app.useGlobalFilters(new HttpExceptionFilter());

    // 4. 전역 검증 파이프
    app.useGlobalPipes(new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }));

    // 5. 전역 인터셉터 (직렬화 → 응답 포맷)
    app.useGlobalInterceptors(
      new ClassSerializerInterceptor(app.get('Reflector')),
      new ResponseInterceptor(),
    );

    // 6. Swagger
    setupSwagger(app);

    await app.listen(process.env.PORT || 3000, '0.0.0.0');
  } catch (error) {
    logger.error('Failed to bootstrap the application');
    logger.error(error);
    process.exit(1);
  }
}
```

`ValidationPipe`의 `forbidNonWhitelisted: true`는 **DTO에 정의되지 않은 필드가 오면 400**을 내므로, 모든 요청 필드를 DTO에 명시해야 한다.

### 6.1 AppModule 구성

```ts
@Module({
  imports: [
    ServeStaticModule.forRoot({ rootPath: PUBLIC_FOLDER_PATH, serveRoot: '/public' }),
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [`.env.${process.env.NODE_ENV || 'local'}`, '.env'],
    }),
    // 레이트리밋: 전역 가드를 두지 않고 업로드/인증 라우트에만 @UseGuards(ThrottlerGuard) 적용
    ThrottlerModule.forRoot([{ name: 'default', ttl: 60_000, limit: 60 }]),
    TypeOrmModule.forRootAsync({ /* 아래 참조 */ }),
    RedisModule,
    /* ...도메인 모듈... */
  ],
})
export class AppModule {}
```

TypeORM 커넥션 풀/타임아웃은 기본값을 쓰지 않는다. 기본값(max 10, 무한 대기)은 비관 잠금 상황에서 요청이 수십 초 매달리는 원인이 된다.

```ts
extra: {
  max: Number(config.get('DB_POOL_MAX') ?? '20'),
  connectionTimeoutMillis: 5000,
  statement_timeout: 15000,
  lock_timeout: 5000,
  idleTimeoutMillis: 30000,
}
```

`synchronize`는 `DB_SYNCHRONIZE === 'true'` 환경변수로만 켠다. **운영에서는 항상 false, DDL은 수동 적용.**

---

## 7. 설정 & 환경변수

| 환경 | `NODE_ENV` | 설정 소스 |
|---|---|---|
| 로컬 | `local` | `.env.local` |
| 개발 | `development` | `.env.development` |
| 운영 | `production` (+ `APP_ENV=prd`) | **AWS SSM Parameter Store** |

- `.env.*`는 커밋하지 않는다 (`.gitignore`).
- 운영 비밀값은 `/{service}/prd/*` 경로의 SSM Parameter Store에 두고, 부팅 시 `injectSsmEnvIfProd()`가 `process.env`에 주입한다.
  - `WithDecryption: true`로 SecureString 복호화, `Recursive` + `NextToken` 페이지네이션.
  - **이미 존재하는 `process.env` 키는 덮어쓰지 않는다** (로컬/CI 오버라이드 보존).
- 새 환경변수를 추가하면 `.env.local`, `.env.development`, SSM **세 곳 모두** 반영해야 한다. SSM 반영은 배포와 순서를 맞춘다.

---

## 8. DTO 규칙

### 8.1 배치

```
dto/
├── request/    # 입력
└── response/   # 출력
```

### 8.2 Request DTO

- 네이밍: **동사 + 대상 + `Dto`** — `CreateUserDto`, `UpdateClusterDto`, `GetCommentsDto`
- `class-validator` 데코레이터로 전 필드 검증.

```ts
export class GetVenueDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(LocationCategory)
  locationCategory?: LocationCategory;

  @IsOptional()
  @IsIn(['recent', 'trending'])
  sort?: 'recent' | 'trending';
}
```

### 8.3 Response DTO

- 네이밍: **`{Target}{Detail}ResponseDto`** — `GetVenueDetailResponseDto`, `GetAllVenueResponseDto`, `CreateClusterResponseDto`
- 모든 필드에 `@ApiProperty` / `@ApiPropertyOptional`로 타입·예시 명시.
- **엔티티를 그대로 반환하지 않는다.** 응답 구조를 명시적으로 선언해 과다 노출을 막는다.
- 중첩 객체는 내부 클래스로 선언하고 `@ApiExtraModels`로 등록.

```ts
@ApiExtraModels(VenueOperatingHourDto)
export class GetVenueDetailResponseDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ description: '유니버설 링크용 공유 식별자 (UUID v4)', example: '550e8400-...' })
  shareUid: string;

  @ApiProperty({ example: 'https://instagram.com/venue_account', nullable: true })
  instagramLink?: string | null;
}
```

---

## 9. Swagger 규칙

- 모든 public API는 문서화한다.
- Controller: `@ApiTags('<Domain> API')`, 인증 필요 시 `@ApiBearerAuth('access-token')`.
- Method: `@ApiOperation({ summary })` + `@ApiResponse({ status: 200|201, description, type, isArray? })`.
- **에러 응답(400/401/…)은 `@ApiResponse`에 정의하지 않는다.** 에러 규약은 공통 포맷(5.3)으로 통일돼 있으므로 문서에 중복시키지 않는다.
- 운영에서는 Swagger를 Basic Auth로 보호하고, 계정 환경변수가 없으면 **문서 자체를 띄우지 않는다**.
- `/api`(UI), `/api-json`, `/api.yaml` 3개 경로를 제공한다. `api.yaml`은 클라이언트 코드 생성용.

---

## 10. 코드 스타일

### 10.1 포맷터 / 린터

`.prettierrc`:

```json
{ "singleQuote": true, "trailingComma": "all" }
```

`eslint.config.mjs`는 flat config + `recommendedTypeChecked` + prettier 통합. 완화하는 룰:

```js
'@typescript-eslint/no-explicit-any': 'off',
'@typescript-eslint/no-floating-promises': 'warn',
'@typescript-eslint/no-unsafe-argument': 'warn',
'@typescript-eslint/no-unsafe-assignment': 'off',
'@typescript-eslint/no-unsafe-member-access': 'off',
'@typescript-eslint/no-unsafe-return': 'off',
```

`tsconfig.json` 핵심: `strictNullChecks: true`, `noImplicitAny: false`, `experimentalDecorators`/`emitDecoratorMetadata` 필수, `target: ES2023`.

### 10.2 코드 단락 (빈 줄) 규칙

**빈 줄 한 줄로 논리 단계를 구분한다.** 같은 단계의 코드는 붙여 쓰고, 단계가 바뀔 때만 빈 줄을 넣는다.

| 단계 | 내용 | 다음에 빈 줄 |
|---|---|---|
| 입력 검증 | 파라미터 유효성 검사 후 throw | ✅ |
| 조회 | Repository/Service 조회 | ✅ |
| 존재 검사 | 조회 결과 null 체크 후 throw | ✅ |
| 비즈니스 검증 | 중복·권한 검사 후 throw | ✅ |
| 실제 수행 | create/update/delete | (메서드 끝) |

```ts
async deleteBookmark(userId: number, venueId: number): Promise<void> {
  const bookmark =
    await this.venueBookmarkRepository.findByUserIdAndVenueId(userId, venueId);
  if (!bookmark) {
    throw new NotFoundException('북마크를 찾을 수 없습니다.');
  }

  await this.venueBookmarkRepository.remove(bookmark);
}
```

- 메서드 사이는 빈 줄 **한 줄**. 두 줄 이상은 쓰지 않는다.
- 컨트롤러의 데코레이터 블록 내부는 붙여 쓴다.

### 10.3 조건문과 비동기 호출

**`if` 조건 안에 `await`를 직접 넣지 않는다.** 결과를 의도가 드러나는 변수에 담은 뒤 조건에 쓴다.

```ts
// ❌
if (!(await this.usersService.isBlockedBy(dto.receiverId, user.id))) { ... }

// ✅
const isReceiverBlockingSender = await this.usersService.isBlockedBy(
  dto.receiverId,
  user.id,
);
if (!isReceiverBlockingSender) { ... }
```

### 10.4 주석

- "무엇을"이 아니라 **"왜"**를 쓴다. 특히 동시성 가드, 타임아웃 값, 우회 처리처럼 코드만 봐서는 이유를 알 수 없는 곳.
- 주석은 한국어로 작성한다.

---

## 11. 테스트

- 파일 위치: **소스 옆** (`services/venues.service.spec.ts`, `repositories/venues.repository.spec.ts`).
- 하나의 서비스에 관심사별로 여러 spec 파일을 두는 것을 허용한다.
  예: `clusters.service.spec.ts`, `clusters.service.moderation.spec.ts`, `clusters.service.suspend.spec.ts`
- **Nest 테스트 모듈(`Test.createTestingModule`)보다 생성자 직접 주입 + `jest.fn()` 목을 우선**한다. 빠르고 의존성 그래프에 끌려다니지 않는다.

```ts
function buildService() {
  const venuesRepository = {
    findByIdForAdmin: jest.fn(),
    save: jest.fn().mockImplementation(async (v) => v),
  };
  const geocodingService = { getLatLngByAddress: jest.fn() };
  const service = new VenuesService(
    {} as never,
    {} as never,
    venuesRepository as never,
    {} as never,
    {} as never,
    geocodingService as never,
  );
  return { service, venuesRepository, geocodingService };
}
```

- 테스트 대상 우선순위: **비즈니스 규칙 > 동시성/트랜잭션 가드 > 유틸 함수 > 단순 CRUD**.
- 검증 명령은 표준 도구를 쓴다: `npx tsc --noEmit -p tsconfig.json`, `npx eslint <paths>`, `npx jest <paths>`.

---

## 12. Git / 협업 컨벤션

### 12.1 브랜치

| 브랜치 | 용도 |
|---|---|
| `main` | 기준 브랜치 |
| `develop` | 통합 개발 브랜치 (기본 작업 대상) |
| `feature/<name>`, `feat/<name>` | 기능 개발 |
| `prd` | **push 시 운영 자동 배포** |

### 12.2 커밋 메시지

Conventional Commits + **한국어 요약**.

```
<type>(<scope>): <요약>

- 선택: 상세 불릿
```

| type | 용도 |
|---|---|
| `feat` | 새로운 기능 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변경 없는 리팩터링 |
| `chore` | 빌드·설정·자동화 |
| `docs` | 문서만 변경 |
| `style` | 포맷/스타일 |

- scope는 도메인·모듈명 (`users`, `auth`, `share`, `db`).
- 요약 72자 이내, 마침표 생략.

```
feat(users): PATCH me 비밀번호 전용 수정, Application 추가/이름 존재 API 분리

- PATCH me: newPassword 필수로 비밀번호만 수정
- POST me/applications: 플랜별 한도·이름 중복 검증 후 애플리케이션 추가
```

### 12.3 이슈 / PR 템플릿

- 이슈 템플릿 4종을 GitHub Form(yml)으로 둔다: Feature / Bug / Refactor / Documentation.
  공통 섹션: `📔 Description` / `✅ Tasks` / `🙋🏻 More`
- PR 제목: `[<이슈 라벨>/<이슈 넘버>] <제목>` (예: `[feat/#3] 사용자 예약 취소`)
- PR 본문: `⚓ Related Issue` / `🚀 Background` / `📔 Description` / `🙋🏻 More`

---

## 13. 배포 파이프라인

`prd` 브랜치 push → GitHub Actions → S3 → CodeDeploy → EC2(pm2).

```
.github/workflows/deploy.yml
  1) checkout → Node 24 setup (npm cache)
  2) npm ci → npm run build
  3) deploy/ 에 dist, package*.json, appspec.yml, scripts/ 를 담아 zip
  4) S3 업로드 (키 = github.sha)
  5) aws deploy create-deployment → aws deploy wait deployment-successful
```

`appspec.yml` 훅:

| 훅 | 스크립트 | 동작 |
|---|---|---|
| AfterInstall | `scripts/install.sh` | `npm ci --omit=dev` |
| ApplicationStart | `scripts/start.sh` | `APP_ENV=prd` 지정 후 `pm2 reload <app> --update-env` (없으면 `pm2 start`) → `pm2 save` |
| ValidateService | `scripts/validate.sh` | `/health` 200 확인, 2초 간격 30회 재시도 |

포인트:

- `start.sh`에서 `APP_ENV=prd`를 export해야 SSM 주입이 동작한다.
- 헬스체크 엔드포인트(`GET /health`)를 `app.controller.ts`에 반드시 둔다.
- 마이그레이션 프레임워크를 쓰지 않는다면 **DDL은 배포 순서에 맞춰 수동 적용**하고, 적용 여부를 문서에 남긴다.

---

## 14. 문서 체계

| 경로 | 내용 |
|---|---|
| `docs/api/` | 프론트엔드 연동 가이드. 엔드포인트·요청/응답 예시·에러 코드 |
| `docs/domain/` | 도메인별 분석 문서 + `README.md` 색인 |
| `docs/superpowers/specs/` | 설계 문서 `YYYY-MM-DD-<기능>-design.md` |
| `docs/superpowers/plans/` | 구현 계획 `YYYY-MM-DD-<기능>.md` |
| `docs/superpowers/reports/` | 구현 결과 리포트 |

도메인 문서는 동일한 골격을 따른다:

```
요약 → 모듈 구성 → 데이터 모델 → API 레퍼런스 → 테스트 현황 → 발견된 문제 → 부록(라우트 요약표)
```

발견 사항은 심각도 등급을 붙이고, 모든 주장은 `파일:줄`로 근거를 표기한다. 확인하지 못한 것은 "미확인"이라고 명시한다.

| 등급 | 의미 |
|---|---|
| 🔴 A | 실동작 결함 — 지금 잘못 동작하거나 보안상 위험 |
| 🟠 B | 검증·정합성 공백 |
| 🟡 C | 성능 — 인덱스 부재, N+1, 페이지네이션 |
| 🔵 D | 설계·일관성 |
| ⚪ E | 정리 — 죽은 코드, lint |

---

## 15. 기능 개발 워크플로

1. **이슈 생성** — 템플릿으로 Description / Tasks 작성
2. **설계** (`docs/superpowers/specs/`) — 데이터 모델 변경, API 계약, 엣지 케이스를 먼저 문서화
3. **계획** (`docs/superpowers/plans/`) — 태스크 단위로 쪼개고 각 태스크의 검증 명령을 명시
4. **브랜치 생성** — `feature/<name>`
5. **구현** — 레이어 순서대로: Entity → Repository → Service → DTO → Controller → Module 등록
6. **테스트** — 비즈니스 규칙 spec 작성
7. **검증** — `npx tsc --noEmit` / `npx eslint` / `npx jest`
8. **커밋** — Conventional Commits (한국어 요약)
9. **PR** — 템플릿 작성, `develop` 대상
10. **배포** — `develop` → `prd` 머지 (DDL이 있으면 순서 조율)
11. **문서 갱신** — 계약이 바뀌면 `docs/api/`, 도메인 구조가 바뀌면 `docs/domain/`

### 새 도메인 추가 체크리스트

- [ ] `src/<domain>/` 생성 + 표준 하위 폴더(`services`, `repositories`, `entities`, `dto/request`, `dto/response`, `const`)
- [ ] `entities/*.entity.ts` — `BaseModel` 상속, `@Entity('<name>_model')`
- [ ] `app.module.ts`의 TypeORM `entities` 배열에 등록
- [ ] `repositories/*.repository.ts` — `@InjectRepository`
- [ ] `services/<domain>.service.ts` — 비즈니스 로직
- [ ] 트랜잭션 필요 시 `services/<domain>-transaction.service.ts`
- [ ] `dto/request`, `dto/response` — 검증 + `@ApiProperty`
- [ ] `<domain>.controller.ts` — Swagger 데코레이터 + 가드
- [ ] `<domain>.module.ts` — `forFeature`, providers, exports
- [ ] `app.module.ts` `imports`에 모듈 등록
- [ ] 도메인 전용 에러가 있으면 `ERROR_CODE`에 섹션 추가
- [ ] spec 작성
- [ ] 운영 DDL 필요 여부 확인

---

## 16. 신규 프로젝트 부트스트랩 체크리스트

- [ ] `nest new <project>` 후 위 의존성 세트 설치
- [ ] `.nvmrc`(24), `package.json`의 `engines` 지정
- [ ] `.prettierrc`, `eslint.config.mjs`, `tsconfig.json` 복사
- [ ] `src/common/` 골격 복사: `entities/base.entity.ts`, `exception/`, `filters/`, `interceptors/`, `config/swagger.config.ts`
- [ ] `src/config/ssm.config.ts` 복사 후 SSM 경로·리전 수정
- [ ] `main.ts` 부트스트랩 순서 적용 (6장)
- [ ] `app.module.ts`에 ConfigModule / TypeORM(풀·타임아웃) / Throttler 설정
- [ ] `GET /health` 엔드포인트 추가
- [ ] `.env.local`, `.env.development` 생성 + `.gitignore` 확인
- [ ] `.github/` 이슈·PR 템플릿, `deploy.yml` 복사 후 리소스명 치환
- [ ] `appspec.yml`, `scripts/{install,start,validate}.sh` 복사 후 경로·앱명 치환
- [ ] `.cursor/rules/`(project-structure, code-paragraphs), `.cursor/skills/commit-conventions`, `.claude/commands/` 복사
- [ ] `docs/{api,domain,superpowers/{specs,plans,reports}}` 디렉터리 생성
- [ ] README를 NestJS 보일러플레이트에서 프로젝트 실제 내용으로 교체

---

## 17. 요약 원칙

1. **DDD 기준 도메인 단위 폴더 구성**
2. **Controller – Service – Repository 레이어 분리**
3. **Repository는 CRUD/쿼리만, 비즈니스 로직은 Service에만**
4. **DTO는 request/response 분리 및 일관된 네이밍**
5. **Swagger로 모든 public API 문서화, 에러는 공통 규약으로**
6. **엔티티는 도메인별 `entities/`에서 관리, `BaseModel` 상속**
7. **공용 코드는 `common/`, 도메인 전용은 그 도메인의 `const/`**
8. **응답은 인터셉터로, 에러는 전역 필터로 단일 포맷 유지**
9. **운영 비밀값은 SSM, `synchronize`는 운영에서 항상 off**
10. **테스트는 소스 옆에, 생성자 직접 주입 목으로**
