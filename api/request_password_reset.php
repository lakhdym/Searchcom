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
require_once __DIR__ . '/helpers/send_reset_email.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Méthode non autorisée'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$identifier = trim($body['identifier'] ?? '');

if ($identifier === '') {
    json_response(['success' => false, 'message' => 'Email ou téléphone requis'], 400);
}

try {
    $pdo = get_pdo();

    // Table password_resets
    $pdo->exec("CREATE TABLE IF NOT EXISTS password_resets (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT NOT NULL,
        token VARCHAR(120) NOT NULL,
        expires_at DATETIME NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_token (token),
        INDEX idx_user (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $stmt = $pdo->prepare('SELECT id, email, phone FROM users WHERE email = :id OR phone = :id LIMIT 1');
    $stmt->execute([':id' => $identifier]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // Réponse générique si l'utilisateur n'existe pas (anti-enum)
    if (!$user) {
        json_response([
            'success' => true,
            'message' => 'Si un compte existe pour cet identifiant, un lien de réinitialisation a été envoyé.',
        ]);
    }

    $token = bin2hex(random_bytes(24));
    $expires = (new DateTime('+15 minutes'))->format('Y-m-d H:i:s');

    // On supprime les précédents tokens de ce user
    $del = $pdo->prepare('DELETE FROM password_resets WHERE user_id = :uid');
    $del->execute([':uid' => $user['id']]);

    $ins = $pdo->prepare('INSERT INTO password_resets (user_id, token, expires_at) VALUES (:uid, :token, :exp)');
    $ins->execute([
        ':uid' => $user['id'],
        ':token' => $token,
        ':exp' => $expires,
    ]);

    if (!empty($user['email'])) {
        sendResetEmail($user['email'], $user['email'], $token);
    }

    json_response([
        'success' => true,
        'message' => 'Si un compte existe pour cet identifiant, un lien de réinitialisation a été envoyé.',
        'token_dev' => $token, // à retirer en prod
    ]);
} catch (Exception $e) {
    error_log('[request_password_reset] ' . $e->getMessage());
    json_response([
        'success' => true,
        'message' => 'Si un compte existe pour cet identifiant, un lien de réinitialisation a été envoyé.',
    ]);
}
