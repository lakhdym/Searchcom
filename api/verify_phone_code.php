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
$phone = trim($body['phone'] ?? '');
$code = trim($body['code'] ?? '');

if (!$phone || !$code) {
    json_response(['success' => false, 'message' => 'Téléphone et code requis'], 400);
}

try {
    $pdo = get_pdo();
    $stmt = $pdo->prepare('SELECT pv.id, pv.user_id, pv.expires_at, pv.verified_at, u.phone_verified_at
                           FROM phone_verifications pv
                           JOIN users u ON u.id = pv.user_id
                           WHERE pv.phone = :phone
                             AND pv.verification_code = :code
                           ORDER BY pv.id DESC
                           LIMIT 1');
    $stmt->execute([':phone' => $phone, ':code' => $code]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        json_response(['success' => false, 'message' => 'Code invalide'], 400);
    }
    if ($row['verified_at']) {
        json_response(['success' => true, 'message' => 'Numéro déjà vérifié']);
    }
    if (strtotime($row['expires_at']) < time()) {
        json_response(['success' => false, 'message' => 'Code expiré'], 400);
    }

    $pdo->beginTransaction();
    $stmt = $pdo->prepare('UPDATE phone_verifications SET verified_at = NOW() WHERE id = ?');
    $stmt->execute([(int)$row['id']]);
    $stmt = $pdo->prepare('UPDATE users SET phone_verified_at = NOW() WHERE id = ?');
    $stmt->execute([(int)$row['user_id']]);
    $pdo->commit();

    json_response(['success' => true, 'message' => 'Numéro vérifié avec succès']);
} catch (Throwable $e) {
    if ($pdo && $pdo->inTransaction()) $pdo->rollBack();
    json_response(['success' => false, 'message' => 'Erreur serveur : ' . $e->getMessage()], 500);
}
