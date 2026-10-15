<?php
declare(strict_types=1);

namespace Smollan\Services;

use Smollan\Support\Env;

final class WhatsAppBusiness {
    public static function configured(): bool {
        return (bool)(Env::get('WHATSAPP_ACCESS_TOKEN') && Env::get('WHATSAPP_PHONE_NUMBER_ID') && Env::get('WHATSAPP_VERIFY_TOKEN'));
    }
    public static function status(): array {
        return [
          'configured'=>self::configured(),
          'provider'=>'WhatsApp Business Platform',
          'features'=>[
            'Project group directory and invite links',
            'Approved operational templates for controlled outbound notifications',
            'Webhook inbox for message status and authorized conversations'
          ],
          'notes'=>'WhatsApp Business API is not the same as automating consumer WhatsApp groups. Group chats/invite links remain links unless the account and API features explicitly support the requested operation.',
        ];
    }
    public static function verifyWebhook(string $mode, string $token, string $challenge): ?string {
        if ($mode==='subscribe' && hash_equals((string)Env::get('WHATSAPP_VERIFY_TOKEN',''), $token) && self::configured()) return $challenge;
        return null;
    }
}
