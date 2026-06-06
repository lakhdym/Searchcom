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

$conversationId = isset($_GET['conversation_id'])
    ? (int)$_GET['conversation_id']
    : (int)($body['conversation_id'] ?? 0);
$requestedUserId = isset($_GET['user_id'])
    ? (int)$_GET['user_id']
    : (int)($body['user_id'] ?? 0);
$userId = require_authenticated_user_id($requestedUserId > 0 ? $requestedUserId : null);

if ($conversationId <= 0) {
    json_response(['success' => false, 'message' => 'conversation_id requis'], 400);
}

try {
    $pdo = get_pdo();

    $stmt = $pdo->prepare('SELECT 1 FROM conversation_participants WHERE conversation_id = :cid AND user_id = :uid LIMIT 1');
    $stmt->execute([':cid' => $conversationId, ':uid' => $userId]);
    if (!$stmt->fetchColumn()) {
        json_response(['success' => false, 'message' => 'Acces non autorise a cette conversation'], 403);
    }

    $accessStmt = $pdo->prepare('
        SELECT c.listing_id, l.user_id AS owner_id, l.type
        FROM conversations c
        JOIN listings l ON l.id = c.listing_id
        WHERE c.id = :cid
        LIMIT 1
    ');
    $accessStmt->execute([':cid' => $conversationId]);
    $conversationMeta = $accessStmt->fetch(PDO::FETCH_ASSOC);
    $pdo->exec("CREATE TABLE IF NOT EXISTS conversation_blocks (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        conversation_id BIGINT NOT NULL,
        blocker_user_id BIGINT NOT NULL,
        blocked_user_id BIGINT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_block (conversation_id, blocker_user_id, blocked_user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $blockStmt = $pdo->prepare('SELECT blocker_user_id, blocked_user_id FROM conversation_blocks WHERE conversation_id = :cid');
    $blockStmt->execute([':cid' => $conversationId]);
    $rows = $blockStmt->fetchAll(PDO::FETCH_ASSOC);
    $isBlocked = !empty($rows);
    $blockedByMe = false;
    $blockedByOther = false;
    foreach ($rows as $row) {
        if ((int)$row['blocker_user_id'] === $userId) {
            $blockedByMe = true;
        } else {
            $blockedByOther = true;
        }
    }

    $hasReply = false;
    $cols = $pdo->query("SHOW COLUMNS FROM messages LIKE 'reply_to_message_id'")->fetchAll(PDO::FETCH_ASSOC);
    if ($cols) {
        $hasReply = true;
    }

    $select = "SELECT
            id,
            conversation_id,
            sender_user_id,
            message_type,
            content,
            media_url,
            created_at,
            CASE WHEN message_type = 'system' AND content = '[deleted]' THEN 1 ELSE 0 END AS is_deleted_for_all,
            CASE WHEN message_type = 'system' AND content = '[deleted]' THEN 'Message supprime' ELSE NULL END AS deleted_text";
    if ($hasReply) {
        $select .= ", reply_to_message_id";
    }
    $select .= " FROM messages WHERE conversation_id = :cid ORDER BY created_at ASC, id ASC";

    $stmt = $pdo->prepare($select);
    $stmt->execute([':cid' => $conversationId]);
    $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $update = $pdo->prepare('UPDATE conversation_participants SET last_read_at = NOW() WHERE conversation_id = :cid AND user_id = :uid');
    $update->execute([':cid' => $conversationId, ':uid' => $userId]);

    json_response([
        'success' => true,
        'items' => $messages,
        'blocked' => $isBlocked,
        'blocked_by_me' => $blockedByMe,
        'blocked_by_other' => $blockedByOther,
    ]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
