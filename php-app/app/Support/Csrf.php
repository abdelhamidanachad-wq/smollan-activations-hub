<?php
declare(strict_types=1);

namespace Smollan\Support;

final class Csrf {
    public static function token(): string {
        if (empty($_SESSION['_csrf'])) $_SESSION['_csrf'] = bin2hex(random_bytes(32));
        return (string)$_SESSION['_csrf'];
    }
    public static function field(): string {
        return '<input type="hidden" name="_csrf" value="' . htmlspecialchars(self::token(), ENT_QUOTES, 'UTF-8') . '">';
    }
    public static function verify(?string $candidate): bool {
        return is_string($candidate) && isset($_SESSION['_csrf']) && hash_equals((string)$_SESSION['_csrf'], $candidate);
    }
}
