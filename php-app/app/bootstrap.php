<?php
declare(strict_types=1);

require_once __DIR__ . '/Support/Env.php';
Smollan\Support\Env::load(dirname(__DIR__) . '/.env');

date_default_timezone_set('Africa/Casablanca');
$isHttps = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off');
session_name('smollan_session');
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'secure' => $isHttps || Smollan\Support\Env::bool('SESSION_SECURE_COOKIE', false),
    'httponly' => true,
    'samesite' => Smollan\Support\Env::get('SESSION_SAME_SITE', 'Lax'),
]);
if (session_status() !== PHP_SESSION_ACTIVE) session_start();
