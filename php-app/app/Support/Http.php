<?php
declare(strict_types=1);

namespace Smollan\Support;

final class Http {
    public static function e(mixed $value): string { return htmlspecialchars((string)($value ?? ''), ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'); }
    public static function redirect(string $path): never { header('Location: ' . $path, true, 303); exit; }
    public static function method(): string { return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET'); }
    public static function flash(string $type, string $message): void { $_SESSION['_flash'] = ['type'=>$type, 'message'=>$message]; }
    public static function takeFlash(): ?array { $f = $_SESSION['_flash'] ?? null; unset($_SESSION['_flash']); return is_array($f) ? $f : null; }
}
