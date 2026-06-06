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
require_once __DIR__ . '/contact_access.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(['success' => false, 'message' => 'Methode non autorisee'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$paymentId = isset($body['payment_id']) ? (int) $body['payment_id'] : 0;
$listingId = isset($body['listing_id']) ? (int) $body['listing_id'] : 0;
$provider = trim((string) ($body['provider'] ?? 'cmi'));
$providerTxnId = trim((string) ($body['provider_txn_id'] ?? ''));

if ($paymentId <= 0 || $listingId <= 0) {
    json_response(['success' => false, 'message' => 'payment_id et listing_id requis'], 400);
}

$userId = require_authenticated_user_id();

try {
    $pdo = get_pdo();

    $payment = load_contact_access_record_by_id($pdo, $paymentId, $listingId);

    if (!$payment) {
        json_response(['success' => false, 'message' => 'Paiement introuvable'], 404);
    }

    if ((int) ($payment['user_id'] ?? 0) !== $userId) {
        json_response(['success' => false, 'message' => 'Acces non autorise'], 403);
    }

    if (($payment['status'] ?? '') !== 'paid') {
        mark_contact_access_record_paid(
            $pdo,
            $payment,
            $provider !== '' ? $provider : 'cmi',
            $providerTxnId !== '' ? $providerTxnId : null,
            json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
        );
    }

    json_response([
        'success' => true,
        'message' => 'Paiement de contact confirme',
    ]);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
