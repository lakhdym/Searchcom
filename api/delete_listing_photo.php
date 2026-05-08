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

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$userId   = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$listingId = isset($body['listing_id']) ? (int)$body['listing_id'] : 0;
$photoId   = isset($body['photo_id']) ? (int)$body['photo_id'] : 0;

if ($userId <= 0 || $listingId <= 0 || $photoId <= 0) {
    json_response(['success' => false, 'message' => 'user_id, listing_id et photo_id requis'], 400);
}

try {
    $pdo = get_pdo();
    $stmt = $pdo->prepare('SELECT user_id FROM listings WHERE id = ? LIMIT 1');
    $stmt->execute([$listingId]);
    $owner = $stmt->fetchColumn();
    if (!$owner) {
        json_response(['success' => false, 'message' => 'Annonce introuvable'], 404);
    }
    if ((int)$owner !== $userId) {
        json_response(['success' => false, 'message' => 'Accès refusé'], 403);
    }

    $del = $pdo->prepare('DELETE FROM listing_photos WHERE id = ? AND listing_id = ?');
    $del->execute([$photoId, $listingId]);

    json_response(['success' => true, 'message' => 'Photo supprimée']);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => 'Erreur serveur : ' . $e->getMessage()], 500);
}
