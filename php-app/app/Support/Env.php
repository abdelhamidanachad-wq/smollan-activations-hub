<?php
declare(strict_types=1);

namespace Smollan\Support;

final class Env {
    private static array $values = [];
    public static function load(string $path): void {
        if (!is_file($path)) return;
        foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
            [$key, $value] = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            if (strlen($value) >= 2 && (($value[0] === '"' && str_ends_with($value, '"')) || ($value[0] === "'" && str_ends_with($value, "'")))) $value = substr($value, 1, -1);
            self::$values[$key] = $value;
            if (getenv($key) === false) putenv($key . '=' . $value);
        }
    }
    public static function get(string $key, ?string $default = null): ?string {
        $v = $_ENV[$key] ?? getenv($key);
        return $v === false || $v === null || $v === '' ? $default : (string)$v;
    }
    public static function bool(string $key, bool $default = false): bool {
        $v = self::get($key);
        if ($v === null) return $default;
        return in_array(strtolower($v), ['1','true','yes','on'], true);
    }
}
