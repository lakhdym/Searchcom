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
require_once __DIR__ . '/jwt_helper.php';
require_once __DIR__ . '/helpers/whatsapp_sender.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
}

$body       = json_decode(file_get_contents('php://input'), true) ?? [];
$identifier = trim($body['identifier'] ?? '');
$password   = $body['password'] ?? '';

if (!$identifier || !$password) {
    json_response(['success' => false, 'message' => 'Identifiant ou mot de passe manquant'], 400);
}

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare(
        'SELECT id, role, full_name, email, phone, avatar_url, preferred_lang, is_banned,
                password_hash, email_verified_at, phone_verified_at
         FROM users
         WHERE email = :id OR phone = :id
         LIMIT 1'
    );
    $stmt->execute([':id' => $identifier]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        json_response(['success' => false, 'message' => 'Identifiant ou mot de passe incorrect'], 401);
    }

    if ((int)$user['is_banned'] === 1) {
        json_response(['success' => false, 'message' => 'Compte banni'], 403);
    }

    if (empty($user['password_hash']) || !password_verify($password, $user['password_hash'])) {
        json_response(['success' => false, 'message' => 'Identifiant ou mot de passe incorrect'], 401);
    }

    $emailVerified = $user['email'] && $user['email_verified_at'] !== null;
    $phoneVerified = $user['phone'] && $user['phone_verified_at'] !== null;
    $anyVerified   = $emailVerified || $phoneVerified;
    $emailNeeds = $user['email'] && !$emailVerified;
    $phoneNeeds = $user['phone'] && !$phoneVerified;

    if (!$anyVerified) {
        // si besoin OTP téléphone on le renvoie systématiquement
        if ($phoneNeeds) {
            $code = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
            $expiresAt = date('Y-m-d H:i:s', time() + 600);
            $stmt = $pdo->prepare('INSERT INTO phone_verifications (user_id, phone, verification_code, expires_at) VALUES (?, ?, ?, ?)');
            $stmt->execute([(int)$user['id'], $user['phone'], $code, $expiresAt]);
            send_whatsapp_otp($user['phone'], $code);
        }

        json_response([
            'success' => false,
            'message' => 'Veuillez vérifier votre compte avant de vous connecter.',
            'requires_email_verification' => $emailNeeds,
            'requires_phone_verification' => $phoneNeeds,
            'email' => $user['email'],
            'phone' => $user['phone'],
            'user_id' => (int)$user['id'],
        ], 401);
    }

    unset($user['password_hash']);

    $token = create_jwt([
        'sub' => (int)$user['id'],
        'email' => $user['email'],
        'role' => $user['role'],
        'iat' => time(),
        'exp' => time() + JWT_TTL,
    ]);

    json_response([
        'success' => true,
        'message' => 'Connexion réussie',
        'token' => $token,
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
