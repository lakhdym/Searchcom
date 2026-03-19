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
    json_response(['success' => false, 'message' => 'Méthode non autorisée'], 405);
}

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$listingId = isset($body['listing_id']) ? (int)$body['listing_id'] : 0;
$userId    = isset($body['user_id']) ? (int)$body['user_id'] : 0;

if ($listingId <= 0 || $userId <= 0) {
    json_response(['success' => false, 'message' => 'listing_id et user_id requis'], 400);
}

try {
    $pdo = get_pdo();

    // Récupère le propriétaire de l'annonce
    $stmt = $pdo->prepare('SELECT user_id FROM listings WHERE id = :lid LIMIT 1');
    $stmt->execute([':lid' => $listingId]);
    $ownerId = (int) $stmt->fetchColumn();
    if ($ownerId === 0) {
        json_response(['success' => false, 'message' => 'Annonce introuvable'], 404);
    }

    if ($ownerId === $userId) {
        json_response(['success' => false, 'message' => 'Vous ne pouvez pas discuter avec votre propre annonce'], 403);
    }

    // Vérifie s'il existe déjà une conversation pour cette annonce avec ces deux participants
    $stmt = $pdo->prepare(
        'SELECT c.id
         FROM conversations c
         JOIN conversation_participants cp1 ON cp1.conversation_id = c.id AND cp1.user_id = :u1
         JOIN conversation_participants cp2 ON cp2.conversation_id = c.id AND cp2.user_id = :u2
         WHERE c.listing_id = :lid
         LIMIT 1'
    );
    $stmt->execute([
        ':u1'  => $userId,
        ':u2'  => $ownerId,
        ':lid' => $listingId,
    ]);
    $existingId = $stmt->fetchColumn();
    if ($existingId) {
        json_response([
            'success' => true,
            'conversation' => [
                'id' => (int)$existingId,
                'listing_id' => $listingId,
            ],
        ]);
    }

    // Crée une nouvelle conversation
    $pdo->beginTransaction();
    $stmt = $pdo->prepare('INSERT INTO conversations (listing_id, created_at) VALUES (:lid, NOW())');
    $stmt->execute([':lid' => $listingId]);
    $convId = (int)$pdo->lastInsertId();

    $stmt = $pdo->prepare('INSERT INTO conversation_participants (conversation_id, user_id, last_read_at) VALUES (:cid, :uid, NULL)');
    $stmt->execute([':cid' => $convId, ':uid' => $userId]);
    $stmt->execute([':cid' => $convId, ':uid' => $ownerId]);

    $pdo->commit();

    json_response([
        'success' => true,
        'conversation' => [
            'id' => $convId,
            'listing_id' => $listingId,
        ],
    ]);
} catch (Exception $e) {
    if ($pdo && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    json_response(['success' => false, 'message' => 'Erreur: '.$e->getMessage()], 500);
}
