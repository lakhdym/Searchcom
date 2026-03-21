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
$conversationId = isset($body['conversation_id']) ? (int)$body['conversation_id'] : 0;
$userId = isset($body['user_id']) ? (int)$body['user_id'] : 0;
$content = trim($body['content'] ?? '');
$messageType = $body['message_type'] ?? 'text';
$replyTo = isset($body['reply_to_message_id']) ? (int)$body['reply_to_message_id'] : null;

if ($conversationId <= 0 || $userId <= 0 || $content === '') {
    json_response(['success' => false, 'message' => 'conversation_id, user_id et content requis'], 400);
}

$allowedTypes = ['text', 'image', 'system'];
if (!in_array($messageType, $allowedTypes, true)) {
    json_response(['success' => false, 'message' => 'message_type invalide'], 400);
}

try {
    $pdo = get_pdo();

    // Vérifier que l'utilisateur fait partie de la conversation
    $stmt = $pdo->prepare('SELECT 1 FROM conversation_participants WHERE conversation_id = :cid AND user_id = :uid LIMIT 1');
    $stmt->execute([':cid' => $conversationId, ':uid' => $userId]);
    if (!$stmt->fetchColumn()) {
        json_response(['success' => false, 'message' => 'Accès refusé à cette conversation'], 403);
    }

    // Vérifier blocage
    $pdo->exec("CREATE TABLE IF NOT EXISTS conversation_blocks (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        conversation_id BIGINT NOT NULL,
        blocker_user_id BIGINT NOT NULL,
        blocked_user_id BIGINT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_block (conversation_id, blocker_user_id, blocked_user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");
    // Blocage ciblé : seul l'utilisateur bloqué est empêché
    // Blocage global : si au moins une entrée existe, personne ne peut envoyer
    $blockStmt = $pdo->prepare('SELECT 1 FROM conversation_blocks WHERE conversation_id = :cid LIMIT 1');
    $blockStmt->execute([':cid' => $conversationId]);
    if ($blockStmt->fetchColumn()) {
        json_response(['success' => false, 'message' => 'Conversation bloquée'], 403);
    }

    // Insérer le message, avec reply_to_message_id si le champ existe
    $hasReplyColumn = false;
    $columns = $pdo->query("SHOW COLUMNS FROM messages LIKE 'reply_to_message_id'")->fetchAll(PDO::FETCH_ASSOC);
    if ($columns) {
        $hasReplyColumn = true;
    }

    if ($hasReplyColumn) {
        $stmt = $pdo->prepare('INSERT INTO messages (conversation_id, sender_user_id, message_type, content, media_url, reply_to_message_id, created_at) VALUES (:cid, :uid, :type, :content, NULL, :reply_to, NOW())');
        $stmt->execute([
            ':cid' => $conversationId,
            ':uid' => $userId,
            ':type' => $messageType,
            ':content' => $content,
            ':reply_to' => $replyTo ?: null,
        ]);
    } else {
        $stmt = $pdo->prepare('INSERT INTO messages (conversation_id, sender_user_id, message_type, content, media_url, created_at) VALUES (:cid, :uid, :type, :content, NULL, NOW())');
        $stmt->execute([
            ':cid' => $conversationId,
            ':uid' => $userId,
            ':type' => $messageType,
            ':content' => $content,
        ]);
    }
    $msgId = (int)$pdo->lastInsertId();

    $stmt = $pdo->prepare('SELECT id, conversation_id, sender_user_id, message_type, content, media_url, created_at FROM messages WHERE id = :id');
    $stmt->execute([':id' => $msgId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    json_response(['success' => true, 'message' => $row]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
