<?php
// api/confirm_publish_payment.php
ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('error_log', __DIR__ . '/api_error.log');
header('Content-Type: application/json; charset=UTF-8');
require_once __DIR__ . '/config.php';

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin) {
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");
}
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['error' => 'Method not allowed'], 405);
}

$auth = $_SERVER['HTTP_AUTHORIZATION'] ?? ($_SERVER['Authorization'] ?? '');
if (!preg_match('/Bearer\s+(.*)$/i', $auth, $m)) {
    json_response(['error' => 'Token manquant'], 401);
}
$payload = verify_jwt($m[1]);
if ($payload === null) {
    json_response(['error' => 'Token invalide'], 401);
}
$userId = isset($payload['sub']) ? (int)$payload['sub'] : 0;
if ($userId <= 0) {
    json_response(['error' => 'Utilisateur invalide'], 401);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$paymentId = isset($body['payment_id']) ? (int)$body['payment_id'] : 0;
$listingId = isset($body['listing_id']) ? (int)$body['listing_id'] : 0;
$provider = $body['provider'] ?? 'cmi';
$providerTxn = $body['provider_txn_id'] ?? null;
$payloadRaw = json_encode($body);

if ($paymentId <= 0 || $listingId <= 0) {
    json_response(['error' => 'payment_id et listing_id requis'], 400);
}

$pdo = get_pdo();

$stmt = $pdo->prepare("SELECT id, user_id, status, amount, currency FROM payments WHERE id = :pid AND listing_id = :lid AND purpose = 'publish' LIMIT 1");
$stmt->execute([':pid' => $paymentId, ':lid' => $listingId]);
$pay = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$pay) {
    json_response(['error' => 'Paiement introuvable'], 404);
}
if ((int)$pay['user_id'] !== $userId) {
    json_response(['error' => 'Paiement non autorisé'], 403);
}
if ($pay['status'] === 'paid') {
    json_response(['success' => true, 'message' => 'Déjà payé']);
}

$pdo->beginTransaction();
try {
    $stmt = $pdo->prepare("UPDATE payments SET status = 'paid', provider = :provider, provider_txn_id = :txn, provider_payload = :payload, paid_at = NOW() WHERE id = :pid");
    $stmt->execute([
        ':provider' => $provider,
        ':txn' => $providerTxn,
        ':payload' => $payloadRaw,
        ':pid' => $paymentId,
    ]);

    $stmt = $pdo->prepare("UPDATE listings SET status = 'published', published_at = NOW() WHERE id = :lid AND status = 'pending_payment'");
    $stmt->execute([':lid' => $listingId]);

    $pdo->commit();
    json_response([
        'success' => true,
        'message' => 'Paiement confirmé, annonce publiée',
    ]);
} catch (Throwable $e) {
    $pdo->rollBack();
    json_response([
        'error' => 'Echec de confirmation paiement',
        'details' => $e->getMessage(),
    ], 500);
}
