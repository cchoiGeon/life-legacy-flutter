import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { App, cert, getApps, initializeApp, ServiceAccount } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { readFileSync } from 'fs';

import { DevicePushTokensService } from './device-push-tokens.service';

export type PushPayload = {
  title: string;
  body?: string;
  data: Record<string, string>;
};

/**
 * FCM 발송. 자격 증명이 없으면 no-op + 로그 (구조는 운영 준비 완료).
 *
 * Env (택1):
 * - FIREBASE_SERVICE_ACCOUNT_PATH — JSON 파일 경로
 * - FIREBASE_PROJECT_ID + FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY
 */
@Injectable()
export class PushSenderService implements OnModuleInit {
  private readonly logger = new Logger(PushSenderService.name);
  private ready = false;
  private app: App | null = null;

  constructor(
    private readonly config: ConfigService,
    private readonly devicePushTokens: DevicePushTokensService,
  ) {}

  onModuleInit(): void {
    this.ready = this.initFirebase();
  }

  get isReady(): boolean {
    return this.ready;
  }

  async sendToUser(userId: string, payload: PushPayload): Promise<void> {
    const tokens = await this.devicePushTokens.listActiveForUser(userId);
    if (tokens.length === 0) {
      this.logger.debug(`No active push tokens for user=${userId}`);
      return;
    }

    if (!this.ready || !this.app) {
      this.logger.warn(
        `Firebase not configured — skip push user=${userId} title="${payload.title}" tokens=${tokens.length}`,
      );
      return;
    }

    const messaging = getMessaging(this.app);
    const invalid: string[] = [];
    const usedIds: string[] = [];

    for (const row of tokens) {
      try {
        await messaging.send({
          token: row.token,
          notification: {
            title: payload.title,
            body: payload.body,
          },
          data: payload.data,
          android: {
            priority: 'high',
            notification: { channelId: 'daily_question' },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                contentAvailable: true,
              },
            },
          },
        });
        usedIds.push(row.id);
      } catch (err) {
        const code =
          err && typeof err === 'object' && 'code' in err
            ? String((err as { code: unknown }).code)
            : '';
        this.logger.warn(
          `FCM send failed user=${userId} code=${code}: ${String(err)}`,
        );
        if (
          code.includes('registration-token-not-registered') ||
          code.includes('invalid-registration-token') ||
          code.includes('messaging/registration-token-not-registered') ||
          code.includes('messaging/invalid-registration-token')
        ) {
          invalid.push(row.token);
        }
      }
    }

    await this.devicePushTokens.markUsed(usedIds);
    await this.devicePushTokens.revokeByTokenValues(invalid);
  }

  private initFirebase(): boolean {
    if (getApps().length > 0) {
      this.app = getApps()[0]!;
      return true;
    }

    try {
      const path = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_PATH');
      if (path) {
        const json = JSON.parse(readFileSync(path, 'utf8')) as ServiceAccount;
        this.app = initializeApp({ credential: cert(json) });
        this.logger.log('Firebase Admin initialized from service account file');
        return true;
      }

      const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
      const clientEmail = this.config.get<string>('FIREBASE_CLIENT_EMAIL');
      const privateKeyRaw = this.config.get<string>('FIREBASE_PRIVATE_KEY');
      if (projectId && clientEmail && privateKeyRaw) {
        const privateKey = privateKeyRaw.replace(/\\n/g, '\n');
        this.app = initializeApp({
          credential: cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
        this.logger.log('Firebase Admin initialized from env credentials');
        return true;
      }

      this.logger.warn(
        'Firebase credentials missing — push sends will be logged only. Set FIREBASE_SERVICE_ACCOUNT_PATH or FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY.',
      );
      return false;
    } catch (err) {
      this.logger.error(`Firebase Admin init failed: ${String(err)}`);
      return false;
    }
  }
}
