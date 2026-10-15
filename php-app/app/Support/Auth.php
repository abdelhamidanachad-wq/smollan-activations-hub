<?php
declare(strict_types=1);

namespace Smollan\Support;

use PDO;
use RuntimeException;

final class Auth {
    public static function user(): ?array { return is_array($_SESSION['user'] ?? null) ? $_SESSION['user'] : null; }
    public static function membership(): ?array { return is_array($_SESSION['membership'] ?? null) ? $_SESSION['membership'] : null; }

    public static function login(PDO $pdo, string $email, string $password): bool {
        $email = strtolower(trim($email));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || !str_ends_with($email, '@smollan.com')) return false;

        $baseUrl = rtrim((string)Env::get('SUPABASE_URL', 'https://ddrohraarhdbwamwnmnu.supabase.co'), '/');
        $apiKey = Env::get('SUPABASE_PUBLISHABLE_KEY');
        if (!$apiKey) throw new RuntimeException('Set SUPABASE_PUBLISHABLE_KEY in the server-side .env file.');
        $body = json_encode(['email'=>$email, 'password'=>$password], JSON_THROW_ON_ERROR);
        $endpoint = $baseUrl . '/auth/v1/token?grant_type=password';
        $headers = ['Content-Type: application/json', 'apikey: ' . $apiKey, 'Accept: application/json'];

        if (function_exists('curl_init')) {
            $ch = curl_init($endpoint);
            curl_setopt_array($ch, [
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => $body,
                CURLOPT_HTTPHEADER => $headers,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_CONNECTTIMEOUT => 8,
                CURLOPT_TIMEOUT => 15,
                CURLOPT_SSL_VERIFYPEER => true,
                CURLOPT_SSL_VERIFYHOST => 2,
            ]);
            $raw = curl_exec($ch);
            $status = (int)curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
            if ($raw === false) {
                error_log('Supabase Auth request failed: ' . curl_error($ch));
                curl_close($ch);
                throw new RuntimeException('Supabase Auth is temporarily unavailable.');
            }
            curl_close($ch);
        } else {
            $context = stream_context_create(['http'=>[
                'method'=>'POST', 'header'=>implode("\r\n", $headers), 'content'=>$body,
                'timeout'=>15, 'ignore_errors'=>true
            ], 'ssl'=>['verify_peer'=>true, 'verify_peer_name'=>true]]);
            $raw = @file_get_contents($endpoint, false, $context);
            $status = 0;
            foreach (($http_response_header ?? []) as $header) {
                if (preg_match('#^HTTP/\S+\s+(\d{3})#', $header, $match)) $status = (int)$match[1];
            }
            if ($raw === false) throw new RuntimeException('Supabase Auth is temporarily unavailable. Enable PHP cURL or verify outbound HTTPS access.');
        }

        $response = json_decode((string)$raw, true);
        if ($status < 200 || $status >= 300 || !is_array($response) || empty($response['user']['id'])) return false;

        $userId = (string)$response['user']['id'];
        $verifiedEmail = strtolower((string)($response['user']['email'] ?? ''));
        if ($verifiedEmail !== $email || !str_ends_with($verifiedEmail, '@smollan.com')) return false;

        $stmt = $pdo->prepare('select user_id::text as user_id, email, display_name, role::text as role, is_active from public.smollan_memberships where user_id = cast(:id as uuid) limit 1');
        $stmt->execute(['id'=>$userId]);
        $membership = $stmt->fetch(PDO::FETCH_ASSOC);
        $active = $membership && in_array($membership['is_active'] ?? false, [true, 't', 'true', 1, '1'], true);
        if (!$membership || !$active || strtolower((string)$membership['email']) !== $verifiedEmail) return false;

        session_regenerate_id(true);
        $_SESSION['user'] = ['id'=>$userId, 'email'=>$verifiedEmail];
        $_SESSION['membership'] = $membership;
        return true;
    }

    public static function logout(): void {
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $p = session_get_cookie_params();
            setcookie(session_name(), '', time()-42000, $p['path'], '', $p['secure'], $p['httponly']);
        }
        session_destroy();
    }
    public static function can(string ...$roles): bool {
        $m = self::membership();
        return !!$m && self::active() && in_array($m['role'] ?? '', $roles, true);
    }
    public static function active(): bool {
        $m = self::membership();
        return !!$m && in_array($m['is_active'] ?? false, [true, 't', 'true', 1, '1'], true);
    }
}
