<?php

header('Content-Type: application/json; charset=UTF-8');

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (preg_match('#^http://localhost:\d+$#', $origin) || preg_match('#^http://127\.0\.0\.1:\d+$#', $origin)) {
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");
}

header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

// ⚠️ حيد credentials إلا ما كتستعملش cookies/session
// header('Access-Control-Allow-Credentials: true');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(["ok" => true]);
    exit;
}



require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['error' => 'Method not allowed'], 405);
}



$body = json_decode(file_get_contents('php://input'), true) ?? [];
$email = $body['email'] ?? null;
$password = $body['password'] ?? null;

if (!$email || !$password) {
    json_response(['error' => 'Email ou mot de passe manquant'], 400);
}

$payload = [
    'sub' => 1,
    'email' => $email,
    'role' => 'user',
    'iat' => time(),
    'exp' => time() + JWT_TTL,
];

$token = create_jwt($payload);

json_response([
    'token' => $token,
    'user' => [
        'id' => 1,
        'name' => 'Utilisateur Demo',
        'email' => $email,
    ],
]);
