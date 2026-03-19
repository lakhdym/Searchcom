<?php

header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(['ok' => true]);
    exit;
}

require_once __DIR__ . '/config.php';

$body = [];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
}

$conversationId = isset($_GET['conversation_id']) ? (int)$_GET['conversation_id'] : (int)($body['conversation_id'] ?? 0);
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : (int)($body['user_id'] ?? 0);

if ($conversationId <= 0 || $userId <= 0) {
    json_response(['success' => false, 'message' => 'conversation_id et user_id requis'], 400);
}

try {
    $pdo = get_pdo();

    // Vérifier que l'utilisateur fait partie de la conversation
    $stmt = $pdo->prepare('SELECT 1 FROM conversation_participants WHERE conversation_id = :cid AND user_id = :uid LIMIT 1');
    $stmt->execute([':cid' => $conversationId, ':uid' => $userId]);
    if (!$stmt->fetchColumn()) {
        json_response(['success' => false, 'message' => 'Accès refusé à cette conversation'], 403);
    }

    $stmt = $pdo->prepare('SELECT id, conversation_id, sender_user_id, message_type, content, media_url, created_at FROM messages WHERE conversation_id = :cid ORDER BY created_at ASC');
    $stmt->execute([':cid' => $conversationId]);
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Mettre à jour last_read_at
    $update = $pdo->prepare('UPDATE conversation_participants SET last_read_at = NOW() WHERE conversation_id = :cid AND user_id = :uid');
    $update->execute([':cid' => $conversationId, ':uid' => $userId]);

    json_response(['success' => true, 'items' => $messages]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
