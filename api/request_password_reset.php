<?php

// Legacy "request_password_reset" kept for backward compatibility.
// Use forgot_password.php / verify_otp.php / reset_password.php for the full OTP flow.

ob_start();
header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); echo json_encode(['ok'=>true]); exit; }

$respond = function(bool $success, string $message, int $status = 200, $error = null, array $extra = []) {
    if (ob_get_length()) { @ob_clean(); }
    http_response_code($status);
    $payload = array_merge(['success'=>$success,'message'=>$message], $error ? ['error'=>$error] : [], $extra);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
};
set_exception_handler(function($e) use ($respond){ $respond(false,'Erreur serveur',500,$e->getMessage()); });
set_error_handler(function($errno,$errstr,$errfile,$errline) use ($respond){ $respond(false,'Erreur serveur',500,"\"$errstr at $errfile:$errline\""); });
register_shutdown_function(function() use ($respond){
    $err = error_get_last();
    if ($err && in_array($err['type'], [E_ERROR,E_PARSE,E_CORE_ERROR,E_COMPILE_ERROR])) {
        $respond(false,'Erreur serveur',500,$err['message']);
    }
});

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/helpers/send_reset_email.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $respond(false,'Méthode non autorisée',405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$identifier = trim($body['identifier'] ?? '');

if ($identifier === '') {
    $respond(false,'Email ou téléphone requis',400);
}

try {
    $pdo = get_pdo();

    // Table password_resets (token par email, 15 min)
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

    // Réponse générique (anti enumeration)
    if (!$user) {
        $respond(true,'Si un compte existe pour cet identifiant, un lien de réinitialisation a été envoyé.');
    }

    $token = bin2hex(random_bytes(24));
    $expires = (new DateTime('+15 minutes'))->format('Y-m-d H:i:s');

    $pdo->prepare('DELETE FROM password_resets WHERE user_id = :uid')->execute([':uid' => $user['id']]);
    $pdo->prepare('INSERT INTO password_resets (user_id, token, expires_at) VALUES (:uid, :token, :exp)')
        ->execute([':uid' => $user['id'], ':token' => $token, ':exp' => $expires]);

    if (!empty($user['email'])) {
        if (!sendResetEmail($user['email'], $user['email'], $token)) {
            throw new Exception('sendResetEmail returned false');
        }
    }

    $respond(true,'Si un compte existe pour cet identifiant, un lien de réinitialisation a été envoyé.',200,null,[
        'token_dev' => $token, // à retirer en prod
    ]);
} catch (Throwable $e) {
    error_log('[request_password_reset] '.$e->getMessage());
    // Réponse générique pour éviter l'énumération et garder une réponse JSON valide
    $respond(true,'Si un compte existe pour cet identifiant, un lien de réinitialisation a été envoyé.');
}
