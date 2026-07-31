import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { AppUserModel } from './entities/app-user.entity';
import { AppUserRepository } from './repositories/app-user.repository';
import { UsersController } from './users.controller';
import { UsersService } from './services/users.service';

@Module({
  imports: [TypeOrmModule.forFeature([AppUserModel]), AuthGuardModule],
  controllers: [UsersController],
  providers: [UsersService, AppUserRepository],
  exports: [UsersService, AppUserRepository],
})
export class UsersModule {}
