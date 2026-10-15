<?php
declare(strict_types=1);

/**
 * SMOLLAN Hostinger PHP bootstrap.
 * Configuration comes from process environment or a private .env file outside public/.
 */
function env_value(string $key, string $default = ''): string {
    $value = getenv($key);
    if ($value !== false && $value !== '') return $value;
    $local = dirname(__DIR__) . '/.env';
    if (is_file($local) && is_readable($local)) {
        foreach (file($local, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
            [$name, $raw] = explode('=', $line, 2);
            if (trim($name) === $key) return trim(trim($raw), "\"'");
        }
    }
    return $default;
}
function e(mixed $value): string {
    return htmlspecialchars((string)$value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
function redirect(string $url): never {
    header('Location: ' . $url, true, 303);
    exit;
}
function csrf_token(): string {
    if (empty($_SESSION['_csrf'])) $_SESSION['_csrf'] = bin2hex(random_bytes(32));
    return $_SESSION['_csrf'];
}
function verify_csrf(): void {
    $sent = (string)($_POST['_csrf'] ?? '');
    if (!hash_equals((string)($_SESSION['_csrf'] ?? ''), $sent)) {
        http_response_code(419);
        exit('Session expired. Please reload the page and try again.');
    }
}
function app_flash(string $type, string $message): void {
    $_SESSION['_flash'][] = ['type'=>$type, 'message'=>$message];
}
function pop_flashes(): array {
    $items = $_SESSION['_flash'] ?? [];
    unset($_SESSION['_flash']);
    return is_array($items) ? $items : [];
}
function current_user(): ?array { return $_SESSION['user'] ?? null; }
function is_logged_in(): bool { return current_user() !== null; }
function has_role(array|string $roles): bool {
    if (!is_logged_in()) return false;
    return in_array((string)(current_user()['role'] ?? ''), (array)$roles, true);
}
function require_login(): void {
    if (!is_logged_in()) redirect('?page=login');
}
function require_roles(array|string $roles): void {
    require_login();
    if (!has_role($roles)) { http_response_code(403); exit('You do not have permission to view this module.'); }
}
function supabase_request(string $method, string $path, ?array $body = null, ?string $accessToken = null): array {
    $base = rtrim(env_value('SUPABASE_URL'), '/');
    $key = env_value('SUPABASE_PUBLISHABLE_KEY');
    if ($base === '' || $key === '') return ['ok'=>false,'status'=>503,'data'=>null,'error'=>'Supabase is not configured.'];
    if (!function_exists('curl_init')) return ['ok'=>false,'status'=>500,'data'=>null,'error'=>'PHP cURL extension is required.'];
    $url = $base . '/rest/v1/' . ltrim($path, '/');
    $headers = ['apikey: '.$key, 'Accept: application/json'];
    $token = $accessToken ?: ($_SESSION['supabase_access_token'] ?? '');
    if ($token !== '') $headers[] = 'Authorization: Bearer '.$token;
    elseif (env_value('SUPABASE_SECRET_KEY') !== '') $headers[] = 'Authorization: Bearer '.env_value('SUPABASE_SECRET_KEY');
    if ($body !== null) $headers[] = 'Content-Type: application/json';
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => strtoupper($method),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_CONNECTTIMEOUT => 8,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
    ]);
    if ($body !== null) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body, JSON_THROW_ON_ERROR));
    $raw = curl_exec($ch);
    $error = curl_error($ch);
    $status = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    if ($raw === false) return ['ok'=>false,'status'=>502,'data'=>null,'error'=>'Supabase network request failed: '.$error];
    $data = json_decode($raw, true);
    return ['ok'=>$status >= 200 && $status < 300, 'status'=>$status, 'data'=>$data, 'error'=>$status >= 300 ? 'Supabase returned HTTP '.$status : null];
}
function supabase_auth_request(string $path, array $body): array {
    $base = rtrim(env_value('SUPABASE_URL'), '/');
    $key = env_value('SUPABASE_PUBLISHABLE_KEY');
    if ($base === '' || $key === '') return ['ok'=>false,'status'=>503,'data'=>null,'error'=>'Authentication is not configured.'];
    $ch = curl_init($base . '/auth/v1/' . ltrim($path, '/'));
    curl_setopt_array($ch, [
        CURLOPT_POST=>true, CURLOPT_RETURNTRANSFER=>true,
        CURLOPT_HTTPHEADER=>['apikey: '.$key,'Content-Type: application/json'],
        CURLOPT_POSTFIELDS=>json_encode($body, JSON_THROW_ON_ERROR),
        CURLOPT_CONNECTTIMEOUT=>8, CURLOPT_TIMEOUT=>20,
        CURLOPT_SSL_VERIFYPEER=>true, CURLOPT_SSL_VERIFYHOST=>2,
    ]);
    $raw = curl_exec($ch); $error = curl_error($ch); $status = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE); curl_close($ch);
    if ($raw === false) return ['ok'=>false,'status'=>502,'data'=>null,'error'=>'Authentication request failed: '.$error];
    $data = json_decode($raw, true);
    return ['ok'=>$status >= 200 && $status < 300, 'status'=>$status, 'data'=>$data, 'error'=>$status >= 300 ? (string)($data['msg'] ?? $data['message'] ?? 'Authentication failed.') : null];
}
$secure = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off');
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_name(env_value('SESSION_NAME', 'smollan_session'));
    session_set_cookie_params(['lifetime'=>0,'path'=>'/','secure'=>$secure,'httponly'=>true,'samesite'=>'Lax']);
    ini_set('session.use_strict_mode', '1');
    ini_set('session.cookie_httponly', '1');
    session_start();
}
header('X-Content-Type-Options: nosniff');
header('Referrer-Policy: strict-origin-when-cross-origin');
header('Permissions-Policy: camera=(self), geolocation=(self), microphone=()');
header('Cache-Control: no-store, private');
