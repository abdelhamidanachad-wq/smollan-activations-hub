<?php
declare(strict_types=1);

namespace Smollan\Support;

use PDO;

final class Auth {
    public static function user(): ?array { return is_array($_SESSION['user'] ?? null) ? $_SESSION['user'] : null; }
    public static function membership(): ?array { return is_array($_SESSION['membership'] ?? null) ? $_SESSION['membership'] : null; }
    public static function login(PDO $pdo, string $email, string $password): bool {
        $stmt = $pdo->prepare('select id, email, encrypted_password, email_confirmed_at from auth.users where lower(email)=lower(:email) limit 1');
        $stmt->execute(['email'=>$email]);
        $u = $stmt->fetch();
        if (!$u || empty($u['email_confirmed_at']) || !self::verifySupabasePassword($password, (string)$u['encrypted_password'])) return false;
        $m = $pdo->prepare('select user_id::text, email, display_name, role::text, is_active from public.smollan_memberships where user_id=:id::uuid limit 1');
        $m->execute(['id'=>$u['id']]);
        $membership = $m->fetch();
        if (!$membership || !filter_var($email, FILTER_VALIDATE_EMAIL) || !str_ends_with(strtolower($email), '@smollan.com') || $membership['is_active'] !== true && $membership['is_active'] !== 't') return false;
        session_regenerate_id(true);
        $_SESSION['user'] = ['id'=>$u['id'], 'email'=>$email];
        $_SESSION['membership'] = $membership;
        return true;
    }
    private static function verifySupabasePassword(string $password, string $stored): bool {
        // Supabase Auth stores bcrypt-compatible hashes for default password storage.
        return str_starts_with($stored, '$2') && password_verify($password, $stored);
    }
    public static function logout(): void { $_SESSION = []; if (ini_get('session.use_cookies')) { $p = session_get_cookie_params(); setcookie(session_name(), '', time()-42000, $p['path'], '', $p['secure'], $p['httponly']); } session_destroy(); }
    public static function can(string ...$roles): bool {
        $m = self::membership();
        return !!$m && in_array($m['role'] ?? '', $roles, true);
    }
    public static function active(): bool { $m=self::membership(); return !!$m && (($m['is_active'] ?? false) === true || ($m['is_active'] ?? false) === 't' || ($m['is_active'] ?? false) === 'true'); }
}
