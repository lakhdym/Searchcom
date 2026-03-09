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
$email = trim($body['email'] ?? '');
$code = trim($body['code'] ?? '');

if (!$email || !$code) {
    json_response(['success' => false, 'message' => 'Email et code requis'], 400);
}

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare(
        'SELECT ev.id, ev.user_id, ev.verification_code, ev.expires_at, ev.verified_at
         FROM email_verifications ev
         WHERE ev.email = :email
         ORDER BY ev.id DESC
         LIMIT 1'
    );
    $stmt->execute([':email' => $email]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        json_response(['success' => false, 'message' => 'Aucun code trouvé'], 404);
    }

    if ($row['verified_at'] !== null) {
        json_response(['success' => true, 'message' => 'Email déjà vérifié'], 200);
    }

    if ($row['verification_code'] !== $code) {
        json_response(['success' => false, 'message' => 'Code invalide'], 400);
    }

    if (strtotime($row['expires_at']) < time()) {
        json_response(['success' => false, 'message' => 'Code expiré'], 400);
    }

    // Valider
    $pdo->beginTransaction();
    $now = date('Y-m-d H:i:s');
    $upd1 = $pdo->prepare('UPDATE email_verifications SET verified_at = :now WHERE id = :id');
    $upd1->execute([':now' => $now, ':id' => $row['id']]);

    $upd2 = $pdo->prepare('UPDATE users SET email_verified_at = :now WHERE id = :uid');
    $upd2->execute([':now' => $now, ':uid' => $row['user_id']]);

    $pdo->commit();

    json_response([
        'success' => true,
        'message' => 'Email vérifié avec succès',
    ]);
} catch (Throwable $e) {
    if ($pdo?->inTransaction()) {
        $pdo->rollBack();
    }
    json_response([
        'success' => false,
        'message' => 'Erreur serveur : ' . $e->getMessage(),
    ], 500);
}
