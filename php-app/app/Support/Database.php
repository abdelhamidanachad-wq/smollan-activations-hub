<?php
declare(strict_types=1);

namespace Smollan\Support;

use PDO;
use PDOException;
use RuntimeException;

final class Database {
    private static ?PDO $pdo = null;
    public static function connection(): PDO {
        if (self::$pdo instanceof PDO) return self::$pdo;
        $host = Env::get('DB_HOST');
        $name = Env::get('DB_NAME', 'postgres');
        $user = Env::get('DB_USER');
        $password = Env::get('DB_PASSWORD');
        if (!$host || !$user || !$password) throw new RuntimeException('Database connection is not configured. Set DB_HOST, DB_USER and DB_PASSWORD in php-app/.env.');
        $port = (int)Env::get('DB_PORT', '5432');
        $sslmode = Env::get('DB_SSLMODE', 'verify-full');
        $dsn = "pgsql:host={$host};port={$port};dbname={$name};sslmode={$sslmode}";
        $ca = Env::get('DB_SSLROOTCERT');
        if ($ca) $dsn .= ';sslrootcert=' . $ca;
        try {
            self::$pdo = new PDO($dsn, $user, $password, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
                PDO::ATTR_STRINGIFY_FETCHES => false,
            ]);
            return self::$pdo;
        } catch (PDOException $e) {
            error_log('SMOLLAN database connection failed: ' . $e->getMessage());
            throw new RuntimeException('Could not connect to the SMOLLAN database. Verify the Supabase pooler settings and SSL certificate.');
        }
    }
}
