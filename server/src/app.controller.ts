import { Controller, Get } from '@nestjs/common';
import { ApiExcludeEndpoint } from '@nestjs/swagger';

@Controller()
export class AppController {
  /** 배포 검증(ValidateService 훅)이 이 응답 200을 기다린다 */
  @ApiExcludeEndpoint()
  @Get('health')
  health() {
    return { status: 'ok' };
  }
}
