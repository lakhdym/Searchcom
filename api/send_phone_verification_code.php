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
require_once __DIR__ . '/helpers/whatsapp_sender.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Method not allowed'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$phone = trim($body['phone'] ?? '');
$userId = isset($body['user_id']) ? (int)$body['user_id'] : 0;

if (!$phone && $userId <= 0) {
    json_response(['success' => false, 'message' => 'phone ou user_id requis'], 400);
}

try {
    $pdo = get_pdo();
    if ($userId > 0 && !$phone) {
        $stmt = $pdo->prepare('SELECT phone FROM users WHERE id = ? LIMIT 1');
        $stmt->execute([$userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row || empty($row['phone'])) {
            json_response(['success' => false, 'message' => 'Téléphone introuvable'], 404);
        }
        $phone = $row['phone'];
    }

    $digits = preg_replace('/\D+/', '', $phone);
    if (strlen($digits) < 6) {
        json_response(['success' => false, 'message' => 'Téléphone invalide'], 400);
    }

    // Vérifier utilisateur
    $stmt = $pdo->prepare('SELECT id FROM users WHERE phone = ? LIMIT 1');
    $stmt->execute([$phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        json_response(['success' => false, 'message' => 'Utilisateur introuvable pour ce téléphone'], 404);
    }
    $uid = (int)$user['id'];

    // Générer OTP
    $code = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
    $expiresAt = date('Y-m-d H:i:s', time() + 600);

    $stmt = $pdo->prepare('INSERT INTO phone_verifications (user_id, phone, verification_code, expires_at) VALUES (?, ?, ?, ?) ');
    $stmt->execute([$uid, $phone, $code, $expiresAt]);

    send_whatsapp_otp($phone, $code);

    json_response([
        'success' => true,
        'message' => 'Code envoyé via WhatsApp',
        'phone' => $phone,
        'expires_at' => $expiresAt,
    ]);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => 'Erreur serveur : ' . $e->getMessage()], 500);
}
