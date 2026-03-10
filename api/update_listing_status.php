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
$userId = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$listingId = isset($body['listing_id']) ? (int)$body['listing_id'] : 0;
$status = $body['status'] ?? '';

$allowed = ['draft','pending_payment','published','hidden','archived'];
if ($userId <= 0 || $listingId <= 0 || !in_array($status, $allowed, true)) {
    json_response(['success' => false, 'message' => 'Paramètres invalides'], 400);
}

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare('SELECT user_id FROM listings WHERE id = :id LIMIT 1');
    $stmt->execute([':id' => $listingId]);
    $ownerId = $stmt->fetchColumn();
    if (!$ownerId || (int)$ownerId !== $userId) {
        json_response(['success' => false, 'message' => 'Non autorisé'], 403);
    }

    $upd = $pdo->prepare('UPDATE listings SET status = :status, updated_at = NOW() WHERE id = :id');
    $upd->execute([':status' => $status, ':id' => $listingId]);

    json_response(['success' => true, 'message' => 'Statut mis à jour']);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => 'Erreur serveur : ' . $e->getMessage()], 500);
}
