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
$userId = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$currentPassword = $body['current_password'] ?? '';
$newPassword = $body['new_password'] ?? '';

if ($userId <= 0 || !$currentPassword || !$newPassword) {
    json_response(['success' => false, 'message' => 'Champs requis manquants'], 400);
}

if (strlen($newPassword) < 8) {
    json_response(['success' => false, 'message' => 'Le nouveau mot de passe doit contenir au moins 8 caractères'], 400);
}

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare('SELECT id, password_hash FROM users WHERE id = :id LIMIT 1');
    $stmt->execute([':id' => $userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        json_response(['success' => false, 'message' => 'Utilisateur introuvable'], 404);
    }

    if (empty($user['password_hash']) || !password_verify($currentPassword, $user['password_hash'])) {
        json_response(['success' => false, 'message' => 'Mot de passe actuel incorrect'], 401);
    }

    $newHash = password_hash($newPassword, PASSWORD_DEFAULT);
    $now = date('Y-m-d H:i:s');

    $upd = $pdo->prepare('UPDATE users SET password_hash = :hash, updated_at = :updated_at WHERE id = :id');
    $upd->execute([':hash' => $newHash, ':updated_at' => $now, ':id' => $userId]);

    json_response(['success' => true, 'message' => 'Mot de passe mis à jour']);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => 'Erreur serveur : ' . $e->getMessage()], 500);
}
