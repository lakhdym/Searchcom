<?php

header('Content-Type: application/json; charset=UTF-8');

$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$email = trim($body['email'] ?? '');
$password = $body['password'] ?? '';

if (!$email || !$password) {
    json_response(['success' => false, 'message' => 'Email ou mot de passe manquant'], 400);
}

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare(
        'SELECT id, role, full_name, email, phone, avatar_url, preferred_lang, is_banned, password_hash
         FROM users
         WHERE email = :email
         LIMIT 1'
    );
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        json_response(['success' => false, 'message' => 'Email ou mot de passe incorrect'], 401);
    }

    if ((int)$user['is_banned'] === 1) {
        json_response(['success' => false, 'message' => 'Compte banni'], 403);
    }

    if (empty($user['password_hash']) || !password_verify($password, $user['password_hash'])) {
        json_response(['success' => false, 'message' => 'Email ou mot de passe incorrect'], 401);
    }

    unset($user['password_hash']);

    json_response([
        'success' => true,
        'message' => 'Connexion réussie',
        'user' => [
            'id' => (int)$user['id'],
            'role' => $user['role'],
            'full_name' => $user['full_name'],
            'email' => $user['email'],
            'phone' => $user['phone'],
            'avatar_url' => $user['avatar_url'],
            'preferred_lang' => $user['preferred_lang'],
            'is_banned' => (int)$user['is_banned'],
        ],
    ]);
} catch (Throwable $e) {
    json_response([
        'success' => false,
        'message' => 'Erreur serveur : ' . $e->getMessage(),
    ], 500);
}
