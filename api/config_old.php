<?php
// api/config.php
// api/config.php

const DB_HOST = 'localhost';
const DB_NAME = 'italents_searchcom';
const DB_USER = 'italents_flutter';        // à adapter
const DB_PASS = 'Pp6QOQ8mbUU)Dl&S';           // à adapter

// Base publique pour servir les photos d'annonces.
// Exemple : photo_url('123.jpg') => https://italents.ma/app/uploads/annonces/123.jpg
const PHOTO_BASE_URL = 'https://italents.ma/app/uploads/annonces/';

function photo_url(string $filename): string
{
    return rtrim(PHOTO_BASE_URL, '/') . '/' . ltrim($filename, '/');
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

// Clé secrète pour signer les JWT (à changer en prod)
const JWT_SECRET = 'f3724ea34aa84913e27a4c581604ssdgk8f6g2azelazeddinea0fe4a256b6406bc4ff931fec59';

// Durée de vie du token (en secondes)
const JWT_TTL = 3600; // 1 heure

// Helper pour répondre en JSON
function json_response($data, int $status = 200)
{
    http_response_code($status);
    echo json_encode($data);
    exit;
}

// Création très simple d’un JWT HS256
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

// Vérification très simple du JWT (sans gestion d’erreurs avancée)
function verify_jwt(string $token): ?array
{
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;

    [$header64, $payload64, $sig64] = $parts;
    $signing_input = $header64 . '.' . $payload64;
    $expected = rtrim(strtr(base64_encode(
        hash_hmac('sha256', $signing_input, JWT_SECRET, true)
    ), '+/', '-_'), '=');

    if (!hash_equals($expected, $sig64)) return null;

    $payload = json_decode(base64_decode(strtr($payload64, '-_', '+/')), true);
    if (!is_array($payload)) return null;

    // Vérifier expiration
    if (isset($payload['exp']) && time() > $payload['exp']) {
        return null;
    }

    return $payload;
}
