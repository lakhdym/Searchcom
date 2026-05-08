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
require_once __DIR__ . '/send_verification_email.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$email = trim($body['email'] ?? '');
$emailLower = strtolower($email);

if (!$email) {
    json_response(['success' => false, 'message' => 'Email requis'], 400);
}

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare('SELECT id, full_name, email_verified_at FROM users WHERE LOWER(email) = :email LIMIT 1');
    $stmt->execute([':email' => $emailLower]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        json_response(['success' => false, 'message' => 'Utilisateur introuvable'], 404);
    }
    if ($user['email_verified_at'] !== null) {
        json_response(['success' => false, 'message' => 'Email déjà vérifié'], 400);
    }

    // nouveau code
    $code = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
    $expiresAt = date('Y-m-d H:i:s', time() + 600);

    $ins = $pdo->prepare('INSERT INTO email_verifications (user_id, email, verification_code, expires_at) VALUES (?, ?, ?, ?)');
    $ins->execute([$user['id'], $emailLower, $code, $expiresAt]);

    send_verification_email($email, $user['full_name'], $code);

    json_response([
        'success' => true,
        'message' => 'Un nouveau code a été envoyé',
        'dev_email_code' => $code, // DEBUG: à retirer en prod
    ]);
} catch (Throwable $e) {
    json_response([
        'success' => false,
        'message' => 'Erreur serveur : ' . $e->getMessage(),
    ], 500);
}
