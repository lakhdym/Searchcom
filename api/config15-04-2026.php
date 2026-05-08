<?php

const DB_HOST = 'localhost';
const DB_NAME = 'italents_searchcom';
const DB_USER = 'italents_flutter';
const DB_PASS = 'Pp6QOQ8mbUU)Dl&S';

const APP_BASE_URL = 'https://italents.ma/app';
const PHOTO_BASE_URL = APP_BASE_URL . '/uploads/annonces/';

function app_base_url(): string
{
    return rtrim(APP_BASE_URL, '/');
}

function uploads_url(string $path): string
{
    $trimmed = trim($path);
    if ($trimmed === '') {
        return '';
    }
    if (preg_match('#^https?://#i', $trimmed)) {
        return $trimmed;
    }

    $cleaned = ltrim($trimmed, '/');
    if (strpos($cleaned, 'uploads/') !== 0) {
        $cleaned = 'uploads/' . $cleaned;
    }

    return app_base_url() . '/' . $cleaned;
}

function photo_url(string $filename): string
{
    return uploads_url('annonces/' . ltrim($filename, '/'));
}

function get_pdo(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4';
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    }
    return $pdo;
}

const JWT_SECRET = 'f3724ea34aa84913e27a4c581604ssdgk8f6g2azelazeddinea0fe4a256b6406bc4ff931fec59';
const JWT_TTL = 3600;

function json_response($data, int $status = 200)
{
    http_response_code($status);
    echo json_encode($data);
    exit;
}

function create_jwt(array $payload): string
{
    $header = ['alg' => 'HS256', 'typ' => 'JWT'];
    $segments = [];
    $segments[] = rtrim(strtr(base64_encode(json_encode($header)), '+/', '-_'), '=');
    $segments[] = rtrim(strtr(base64_encode(json_encode($payload)), '+/', '-_'), '=');
    $signing_input = implode('.', $segments);
    $signature = hash_hmac('sha256', $signing_input, JWT_SECRET, true);
    $segments[] = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
    return implode('.', $segments);
}

function verify_jwt(string $token): ?array
{
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return null;
    }

    [$header64, $payload64, $sig64] = $parts;
    $signing_input = $header64 . '.' . $payload64;
    $expected = rtrim(strtr(base64_encode(
        hash_hmac('sha256', $signing_input, JWT_SECRET, true)
    ), '+/', '-_'), '=');

    if (!hash_equals($expected, $sig64)) {
        return null;
    }

    $payload = json_decode(base64_decode(strtr($payload64, '-_', '+/')), true);
    if (!is_array($payload)) {
        return null;
    }

    if (isset($payload['exp']) && time() > $payload['exp']) {
        return null;
    }

    return $payload;
}

function get_authorization_header(): string
{
    return $_SERVER['HTTP_AUTHORIZATION']
        ?? ($_SERVER['Authorization'] ?? ($_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? ''));
}

function get_bearer_token(): ?string
{
    $auth = get_authorization_header();
    if ($auth && preg_match('/Bearer\s+(.*)$/i', $auth, $matches)) {
        return trim($matches[1]);
    }
    return null;
}

function require_authenticated_user(): array
{
    $token = get_bearer_token();
    if (!$token) {
        json_response(['success' => false, 'message' => 'Veuillez vous reconnecter'], 401);
    }

    $payload = verify_jwt($token);
    if (!is_array($payload) || (int)($payload['sub'] ?? 0) <= 0) {
        json_response(['success' => false, 'message' => 'Veuillez vous reconnecter'], 401);
    }

    return $payload;
}

function require_authenticated_user_id(?int $expectedUserId = null): int
{
    $payload = require_authenticated_user();
    $userId = (int)($payload['sub'] ?? 0);

    if ($userId <= 0) {
        json_response(['success' => false, 'message' => 'Veuillez vous reconnecter'], 401);
    }

    if ($expectedUserId !== null && $expectedUserId > 0 && $expectedUserId !== $userId) {
        json_response(['success' => false, 'message' => 'Acces non autorise'], 403);
    }

    return $userId;
}
