<?php

// Robust JSON response wrapper to Ã©viter les sorties partielles
ob_start();
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

// Safe responder
$respond = function(bool $success, string $message, int $status = 200, $error = null, array $extra = []) {
    if (ob_get_length()) { @ob_clean(); }
    http_response_code($status);
    $payload = array_merge(['success' => $success, 'message' => $message], $error ? ['error' => $error] : [], $extra);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
};

set_exception_handler(function($e) use ($respond) {
    $respond(false, 'Erreur serveur', 500, $e->getMessage());
});
set_error_handler(function($errno, $errstr, $errfile, $errline) use ($respond) {
    $respond(false, 'Erreur serveur', 500, "$errstr at $errfile:$errline");
});
register_shutdown_function(function() use ($respond) {
    $err = error_get_last();
    if ($err && in_array($err['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        $respond(false, 'Erreur serveur', 500, $err['message']);
    }
});

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/send_verification_email.php';
require_once __DIR__ . '/helpers/whatsapp_sender.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $respond(false, 'Method not allowed', 405);
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
if (!$email && !$phone) {
    $errors[] = 'Email ou tÃ©lÃ©phone requis';
}
if ($email && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors[] = 'Email invalide';
}
if ($phone) {
    $digits = preg_replace('/\D+/', '', $phone);
    if (strlen($digits) < 6) {
        $errors[] = 'TÃ©lÃ©phone invalide';
    }
}
if (strlen($password) < 8) {
    $errors[] = 'Mot de passe trop court (min 8)';
}
$allowedLangs = ['fr', 'ar', 'en'];
if (!in_array($preferredLang, $allowedLangs, true)) {
    $preferredLang = 'fr';
}

if ($errors) {
    $respond(false, implode(', ', $errors), 400);
}

try {
    $pdo = get_pdo();

    // Tables de vÃ©rification si elles n'existent pas encore
    $pdo->exec("CREATE TABLE IF NOT EXISTS email_verifications (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT NOT NULL,
        email VARCHAR(255) NOT NULL,
        verification_code VARCHAR(10) NOT NULL,
        expires_at DATETIME NOT NULL,
        verified_at DATETIME NULL DEFAULT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_email (email),
        INDEX idx_user (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $pdo->exec("CREATE TABLE IF NOT EXISTS phone_verifications (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT NOT NULL,
        phone VARCHAR(50) NOT NULL,
        verification_code VARCHAR(10) NOT NULL,
        expires_at DATETIME NOT NULL,
        verified_at DATETIME NULL DEFAULT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_phone (phone),
        INDEX idx_user (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    // VÃ©rifier unicitÃ© email / phone
    if ($email) {
        $stmt = $pdo->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
        $stmt->execute([$email]);
        if ($stmt->fetch()) {
            json_response(['success' => false, 'message' => 'Email dÃ©jÃ  utilisÃ©'], 409);
        }
    }
    if ($phone) {
        $stmt = $pdo->prepare('SELECT id FROM users WHERE phone = ? LIMIT 1');
        $stmt->execute([$phone]);
        if ($stmt->fetch()) {
            json_response(['success' => false, 'message' => 'TÃ©lÃ©phone dÃ©jÃ  utilisÃ©'], 409);
        }
    }

    $passwordHash = password_hash($password, PASSWORD_DEFAULT);
    $now = date('Y-m-d H:i:s');

    $stmt = $pdo->prepare(
        'INSERT INTO users (role, full_name, email, phone, password_hash, preferred_lang, is_banned, email_verified_at, phone_verified_at, created_at, updated_at)
         VALUES (:role, :full_name, :email, :phone, :password_hash, :preferred_lang, 0, NULL, NULL, :created_at, :updated_at)'
    );

    $stmt->execute([
        ':role' => 'user',
        ':full_name' => $fullName,
        ':email' => $email ?: null,
        ':phone' => $phone ?: null,
        ':password_hash' => $passwordHash,
        ':preferred_lang' => $preferredLang,
        ':created_at' => $now,
        ':updated_at' => $now,
    ]);

    $userId = (int)$pdo->lastInsertId();

    $requiresEmail = false;
    $requiresPhone = false;
    $devEmailCode = null;
    $devPhoneCode = null;

    if ($email) {
        try {
            $code = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiresAt = date('Y-m-d H:i:s', time() + 600);
            $stmt = $pdo->prepare('INSERT INTO email_verifications (user_id, email, verification_code, expires_at) VALUES (?, ?, ?, ?)');
            $stmt->execute([$userId, $email, $code, $expiresAt]);
            send_verification_email($email, $fullName, $code);
            $requiresEmail = true;
            $devEmailCode = $code; // DEBUG: Ã  retirer en prod
        } catch (Throwable $e) {
            error_log('[register.php] email verif send failed: '.$e->getMessage());
        }
    }

    if ($phone) {
        try {
            $code = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiresAt = date('Y-m-d H:i:s', time() + 600);
            $stmt = $pdo->prepare('INSERT INTO phone_verifications (user_id, phone, verification_code, expires_at) VALUES (?, ?, ?, ?)');
            $stmt->execute([$userId, $phone, $code, $expiresAt]);
            send_whatsapp_otp($phone, $code);
            $requiresPhone = true;
            $devPhoneCode = $code; // DEBUG: Ã  retirer en prod
        } catch (Throwable $e) {
            error_log('[register.php] phone verif send failed: '.$e->getMessage());
        }
    }

    json_response([
        'success' => true,
        'message' => $requiresPhone
            ? 'Compte crÃ©Ã©. VÃ©rifiez votre numÃ©ro via WhatsApp.'
            : 'Compte crÃ©Ã©. VÃ©rifiez votre email.',
        'requires_email_verification' => $requiresEmail,
        'requires_phone_verification' => $requiresPhone,
        'user_id' => $userId,
        'email' => $email,
        'phone' => $phone,
        'dev_email_code' => $devEmailCode,
        'dev_phone_code' => $devPhoneCode,
    ]);
} catch (Throwable $e) {
    error_log('[register.php] '.$e->getMessage().' @ '.$e->getFile().':'.$e->getLine());
    json_response([
        'success' => false,
        'message' => 'Erreur serveur : ' . $e->getMessage(),
    ], 500);
}
