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
    json_response(['success' => false, 'message' => 'Méthode non autorisée'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$identifier = trim($body['identifier'] ?? '');
$otp = trim($body['otp'] ?? '');

if ($identifier === '' || strlen($otp) < 4) {
    json_response(['success' => false, 'message' => 'Identifiant et code requis'], 400);
}

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare('SELECT id FROM users WHERE email = :id OR phone = :id LIMIT 1');
    $stmt->execute([':id' => $identifier]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        json_response(['success' => false, 'message' => 'Code invalide'], 400);
    }

    $stmt = $pdo->prepare('SELECT * FROM password_resets WHERE user_id = :uid AND otp_code = :otp ORDER BY created_at DESC LIMIT 1');
    $stmt->execute([':uid' => $user['id'], ':otp' => $otp]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        json_response(['success' => false, 'message' => 'Code invalide'], 400);
    }

    if ((int)$row['attempts'] >= 5) {
        json_response(['success' => false, 'message' => 'Trop de tentatives, recommencez'], 429);
    }

    if (new DateTime($row['expires_at']) < new DateTime()) {
        json_response(['success' => false, 'message' => 'Code expiré'], 400);
    }

    $resetToken = bin2hex(random_bytes(24));
    $upd = $pdo->prepare('UPDATE password_resets SET reset_token = :tok WHERE id = :id');
    $upd->execute([':tok' => $resetToken, ':id' => $row['id']]);

    json_response([
        'success' => true,
        'message' => 'Code validé',
        'reset_token' => $resetToken,
        'expires_at' => $row['expires_at'],
    ]);
} catch (Throwable $e) {
    error_log('[verify_otp] ' . $e->getMessage());
    json_response(['success' => false, 'message' => 'Erreur serveur'], 500);
}
