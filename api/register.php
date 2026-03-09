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

$fullName = trim($body['full_name'] ?? '');
$email = trim($body['email'] ?? '');
$phone = trim($body['phone'] ?? '');
$password = $body['password'] ?? '';
$preferredLang = $body['preferred_lang'] ?? 'fr';

$errors = [];
if (mb_strlen($fullName) < 2) {
    $errors[] = 'Nom complet invalide';
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors[] = 'Email invalide';
}
if (strlen($password) < 8) {
    $errors[] = 'Mot de passe trop court (min 8)';
}
$allowedLangs = ['fr', 'ar', 'en'];
if (!in_array($preferredLang, $allowedLangs, true)) {
    $preferredLang = 'fr';
}

if ($errors) {
    json_response(['success' => false, 'message' => implode(', ', $errors)], 400);
}

try {
    $pdo = get_pdo();

    // Email unique
    $stmt = $pdo->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        json_response(['success' => false, 'message' => 'Email déjà utilisé'], 409);
    }

    $passwordHash = password_hash($password, PASSWORD_DEFAULT);
    $now = date('Y-m-d H:i:s');

    $stmt = $pdo->prepare(
        'INSERT INTO users (role, full_name, email, phone, password_hash, preferred_lang, is_banned, created_at, updated_at)
         VALUES (:role, :full_name, :email, :phone, :password_hash, :preferred_lang, 0, :created_at, :updated_at)'
    );

    $stmt->execute([
        ':role' => 'user',
        ':full_name' => $fullName,
        ':email' => $email,
        ':phone' => $phone ?: null,
        ':password_hash' => $passwordHash,
        ':preferred_lang' => $preferredLang,
        ':created_at' => $now,
        ':updated_at' => $now,
    ]);

    $userId = (int)$pdo->lastInsertId();

    json_response([
        'success' => true,
        'message' => 'Compte créé avec succès',
        'user' => [
            'id' => $userId,
            'role' => 'user',
            'full_name' => $fullName,
            'email' => $email,
            'phone' => $phone ?: null,
            'avatar_url' => null,
            'preferred_lang' => $preferredLang,
            'is_banned' => 0,
        ],
    ]);
} catch (Throwable $e) {
    json_response([
        'success' => false,
        'message' => 'Erreur serveur : ' . $e->getMessage(),
    ], 500);
}
