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
$listingId = isset($body['listing_id']) ? (int) $body['listing_id'] : 0;

if ($listingId <= 0) {
    json_response(['success' => false, 'message' => 'listing_id requis'], 400);
}

$userId = require_authenticated_user_id();

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare('
        SELECT id, user_id, type, status
        FROM listings
        WHERE id = :lid
        LIMIT 1
    ');
    $stmt->execute([':lid' => $listingId]);
    $listing = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$listing) {
        json_response(['success' => false, 'message' => 'Annonce introuvable'], 404);
    }

    $ownerId = (int) ($listing['user_id'] ?? 0);
    $type = (string) ($listing['type'] ?? '');
    $status = (string) ($listing['status'] ?? '');

    if ($ownerId === $userId) {
        json_response(['success' => false, 'message' => 'Vous ne pouvez pas contacter votre propre annonce'], 403);
    }

    if ($type !== 'found') {
        json_response([
            'success' => true,
            'has_access' => true,
            'requires_payment' => false,
        ]);
    }

    if ($status !== 'published') {
        json_response(['success' => false, 'message' => 'Cette annonce n\'est pas disponible pour contact'], 403);
    }

    $pricing = contact_access_pricing($pdo);
    $amount = (float) $pricing['amount'];
    $currency = (string) $pricing['currency'];

    $paidAccess = find_contact_access_paid_record($pdo, $userId, $listingId);
    if ($paidAccess) {
        json_response([
            'success' => true,
            'has_access' => true,
            'requires_payment' => false,
            'payment_id' => (int) $paidAccess['id'],
            'amount' => (string) ($paidAccess['amount'] ?? $amount),
            'currency' => (string) ($paidAccess['currency'] ?? $currency),
        ]);
    }

    $pendingAccess = find_contact_access_pending_record($pdo, $userId, $listingId);
    if ($pendingAccess) {
        json_response([
            'success' => true,
            'has_access' => false,
            'requires_payment' => true,
            'payment_id' => (int) $pendingAccess['id'],
            'amount' => (string) ($pendingAccess['amount'] ?? $amount),
            'currency' => (string) ($pendingAccess['currency'] ?? $currency),
        ]);
    }

    $createdAccess = create_contact_access_pending_record(
        $pdo,
        $userId,
        $listingId,
        $amount,
        $currency
    );

    json_response([
        'success' => true,
        'has_access' => false,
        'requires_payment' => true,
        'payment_id' => (int) $createdAccess['id'],
        'amount' => (string) ($createdAccess['amount'] ?? $amount),
        'currency' => (string) ($createdAccess['currency'] ?? $currency),
    ]);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
