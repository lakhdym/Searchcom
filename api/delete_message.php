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
$messageId = isset($body['message_id']) ? (int)$body['message_id'] : 0;
$userId    = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$deleteAll = !empty($body['delete_for_all']);

if ($messageId <= 0 || $userId <= 0) {
    json_response(['success' => false, 'message' => 'message_id et user_id requis'], 400);
}

try {
    $pdo = get_pdo();

    // Récupérer le message et la conversation
    $stmt = $pdo->prepare('SELECT id, conversation_id, sender_user_id FROM messages WHERE id = :id');
    $stmt->execute([':id' => $messageId]);
    $msg = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$msg) {
        json_response(['success' => false, 'message' => 'Message introuvable'], 404);
    }

    $conversationId = (int)$msg['conversation_id'];
    $senderId       = (int)$msg['sender_user_id'];

    // Vérifier que l'utilisateur appartient à la conversation
    $check = $pdo->prepare('SELECT 1 FROM conversation_participants WHERE conversation_id = :cid AND user_id = :uid LIMIT 1');
    $check->execute([':cid' => $conversationId, ':uid' => $userId]);
    if (!$check->fetchColumn()) {
        json_response(['success' => false, 'message' => 'Accès refusé à cette conversation'], 403);
    }

    if ($deleteAll) {
        // Seul l'expéditeur peut supprimer pour tous
        if ($senderId !== $userId) {
            json_response(['success' => false, 'message' => 'Seul l\'expéditeur peut supprimer pour tous'], 403);
        }
        // Soft delete : marquer comme supprimé pour tous
        $del = $pdo->prepare('UPDATE messages SET message_type = :type, content = :content, media_url = NULL WHERE id = :id');
        $del->execute([
            ':type' => 'system',
            ':content' => '[deleted]',
            ':id' => $messageId,
        ]);
    } else {
        // Suppression pour soi uniquement : on ne touche pas au message global.
        // Le client gère la suppression locale. On retourne success.
    }

    json_response(['success' => true]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
