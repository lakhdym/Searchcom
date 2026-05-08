<?php
// forgot_password.php - reset via OTP
ob_start();
header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); echo json_encode(['ok'=>true]); exit; }

// global safe responders & handlers
$respond = function(bool $success, string $message, int $status = 200, $error = null, array $extra = []) {
    if (ob_get_length()) { @ob_clean(); }
    http_response_code($status);
    $payload = array_merge(['success'=>$success,'message'=>$message], $error ? ['error'=>$error] : [], $extra);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
};
set_exception_handler(function($e) use ($respond){
    $respond(false,'Erreur serveur',500,$e->getMessage());
});
set_error_handler(function($errno,$errstr,$errfile,$errline) use ($respond){
    $respond(false,'Erreur serveur',500,"$errstr at $errfile:$errline");
});
register_shutdown_function(function() use ($respond){
    $err = error_get_last();
    if ($err && in_array($err['type'], [E_ERROR,E_PARSE,E_CORE_ERROR,E_COMPILE_ERROR])) {
        $respond(false,'Erreur serveur',500,$err['message']);
    }
});

try {
    require_once __DIR__.'/config.php';
} catch (Throwable $e) {
    $respond(false,'Erreur serveur',500,'Include config: '.$e->getMessage());
}

// charger helper email si dispo, sinon stub mail()
if (file_exists(__DIR__.'/helpers/send_reset_email.php')) {
    require_once __DIR__.'/helpers/send_reset_email.php';
} else {
    function sendOtpEmail(string $email, string $name, string $otp): bool {
        @mail($email, 'Code de réinitialisation', "Votre code OTP: $otp (valable 10 minutes)");
        return true;
    }
}
// charger helper whatsapp si dispo, sinon stub log
if (file_exists(__DIR__.'/helpers/whatsapp_sender.php')) {
    require_once __DIR__.'/helpers/whatsapp_sender.php';
} else {
    function send_whatsapp_otp(string $phone, string $otp): bool {
        error_log("[OTP WhatsApp stub] $phone -> $otp");
        return true;
    }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $respond(false,'Méthode non autorisée',405);
}

$body = json_decode(file_get_contents('php://input'), true);
if (!is_array($body)) {
    $respond(false,'Payload JSON invalide',400,'body_parse_error');
}
$rawIdentifier = trim((string)($body['identifier'] ?? ''));
if ($rawIdentifier === '') {
    $respond(false,'Email ou téléphone requis',400);
}

// Normalisation téléphone pour limiter les échecs de matching
$normalizePhone = function(string $v): string {
    // garde uniquement les chiffres, retire +, espaces, tirets, points, parenthèses
    return preg_replace('/\D+/', '', $v ?? '');
};

// email en minuscule, phone en chiffres uniquement
$identifierEmail = strtolower($rawIdentifier);
$identifierPhone = $normalizePhone($rawIdentifier);

try {
    $pdo = get_pdo();
    $pdo->exec("CREATE TABLE IF NOT EXISTS password_resets (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        user_id BIGINT NOT NULL,
        otp_code VARCHAR(6) NOT NULL,
        reset_token VARCHAR(120) DEFAULT NULL,
        expires_at DATETIME NOT NULL,
        attempts INT NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_user (user_id),
        UNIQUE KEY uniq_token (reset_token)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    // compat MySQL 5.7+: pas de REGEXP_REPLACE -> enchaînement de REPLACE
    $stmt = $pdo->prepare('SELECT id, full_name, email, phone
        FROM users
        WHERE LOWER(email) = :email
           OR REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone," ",""),"+",""),"-",""),".",""),"(",""),")","") = :phone
        LIMIT 1');
    $stmt->execute([':email'=>$identifierEmail, ':phone'=>$identifierPhone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        $respond(true,'Si un compte existe, un code a été envoyé.');
    }

    $otp = str_pad((string)random_int(0,999999), 6, '0', STR_PAD_LEFT);
    $expires = date('Y-m-d H:i:s', time()+600);

    $pdo->prepare('DELETE FROM password_resets WHERE user_id = :uid')->execute([':uid'=>$user['id']]);
    $pdo->prepare('INSERT INTO password_resets (user_id, otp_code, expires_at) VALUES (:uid,:otp,:exp)')
        ->execute([':uid'=>$user['id'], ':otp'=>$otp, ':exp'=>$expires]);

    $channel = 'email';
    if (filter_var($rawIdentifier, FILTER_VALIDATE_EMAIL) && !empty($user['email'])) {
        sendOtpEmail($user['email'], $user['full_name'] ?: $user['email'], $otp);
    } elseif (!empty($user['phone'])) {
        $channel = 'whatsapp';
        send_whatsapp_otp($user['phone'], $otp);
    }

    $respond(true,'Code envoyé',200,null,[
        'channel'=>$channel,
        'expires_at'=>$expires,
        'otp_dev'=>$otp // à retirer en prod
    ]);
} catch (Throwable $e) {
    error_log('[forgot_password] '.$e->getMessage());
    $respond(false,'Erreur serveur',500,$e->getMessage());
}
