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
$token = trim($body['token'] ?? '');
$newPassword = (string)($body['new_password'] ?? '');

if ($token === '' || strlen($newPassword) < 8) {
    json_response(['success' => false, 'message' => 'Token et mot de passe (>=8) requis'], 400);
}

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare('SELECT pr.user_id, pr.expires_at FROM password_resets pr WHERE pr.reset_token = :tok LIMIT 1');
    $stmt->execute([':tok' => $token]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        json_response(['success' => false, 'message' => 'Token invalide'], 400);
    }
    if (new DateTime($row['expires_at']) < new DateTime()) {
        json_response(['success' => false, 'message' => 'Token expiré'], 400);
    }

    $hash = password_hash($newPassword, PASSWORD_DEFAULT);
    $upd = $pdo->prepare('UPDATE users SET password_hash = :hash, updated_at = NOW() WHERE id = :uid');
    $upd->execute([':hash' => $hash, ':uid' => $row['user_id']]);

    $del = $pdo->prepare('DELETE FROM password_resets WHERE reset_token = :tok');
    $del->execute([':tok' => $token]);

    json_response(['success' => true, 'message' => 'Mot de passe réinitialisé']);
} catch (Throwable $e) {
    error_log('[reset_password] ' . $e->getMessage());
    json_response(['success' => false, 'message' => 'Erreur serveur'], 500);
}
