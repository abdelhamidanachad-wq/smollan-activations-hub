<?php
declare(strict_types=1);

namespace Smollan\Services;

use Smollan\Support\Env;

final class GoogleWorkspace {
    public static function configured(): bool {
        return (bool)(Env::get('GOOGLE_CLIENT_ID') && Env::get('GOOGLE_CLIENT_SECRET') && Env::get('GOOGLE_REDIRECT_URI'));
    }
    public static function status(): array {
        return [
          'configured'=>self::configured(),
          'provider'=>'Google Workspace',
          'features'=>[
            ['name'=>'Google Drive','status'=>self::configured()?'OAuth credentials configured':'Needs OAuth client + consent screen','scope'=>'Drive folder/file index and project briefs'],
            ['name'=>'Gmail','status'=>self::configured()?'OAuth credentials configured':'Needs OAuth client + consent screen','scope'=>'Read or draft messages only after per-user consent'],
            ['name'=>'Google Sheets','status'=>self::configured()?'OAuth credentials configured':'Needs OAuth client + consent screen','scope'=>'Read/import project trackers after per-user consent'],
          ],
          'security'=>'Use per-user OAuth, minimal scopes and encrypted refresh tokens. No service account or browser-exposed client secret.',
        ];
    }
}
