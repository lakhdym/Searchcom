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

$requestedUserId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : (int)($body['user_id'] ?? 0);
$userId = require_authenticated_user_id($requestedUserId > 0 ? $requestedUserId : null);

try {
    $pdo = get_pdo();
    $pdo->exec("CREATE TABLE IF NOT EXISTS conversation_blocks (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        conversation_id BIGINT NOT NULL,
        blocker_user_id BIGINT NOT NULL,
        blocked_user_id BIGINT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uniq_block (conversation_id, blocker_user_id, blocked_user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $sql = "
        SELECT
            c.id,
            c.listing_id,
            l.title AS listing_title,
            (SELECT u2.id FROM conversation_participants cp2 JOIN users u2 ON u2.id = cp2.user_id
             WHERE cp2.conversation_id = c.id AND cp2.user_id <> :uid LIMIT 1) AS other_user_id,
            (SELECT u2.full_name FROM conversation_participants cp2 JOIN users u2 ON u2.id = cp2.user_id
             WHERE cp2.conversation_id = c.id AND cp2.user_id <> :uid LIMIT 1) AS other_user_name,
            (SELECT m.content FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC, m.id DESC LIMIT 1) AS last_message,
            (SELECT m.message_type FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC, m.id DESC LIMIT 1) AS last_message_type,
            (SELECT m.media_url FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC, m.id DESC LIMIT 1) AS last_media_url,
            (SELECT m.sender_user_id FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC, m.id DESC LIMIT 1) AS last_sender_user_id,
            (SELECT m.created_at FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC, m.id DESC LIMIT 1) AS last_message_at,
            COALESCE((
                SELECT COUNT(*) FROM messages m
                JOIN conversation_participants cpRead ON cpRead.conversation_id = m.conversation_id AND cpRead.user_id = :uid
                WHERE m.conversation_id = c.id
                  AND m.sender_user_id <> :uid
                  AND (cpRead.last_read_at IS NULL OR m.created_at > cpRead.last_read_at)
            ), 0) AS unread_count,
            (SELECT CASE WHEN EXISTS(
                SELECT 1 FROM conversation_blocks b WHERE b.conversation_id = c.id AND b.blocker_user_id = :uid
            ) THEN 1 ELSE 0 END) AS blocked_by_me,
            (SELECT CASE WHEN EXISTS(
                SELECT 1 FROM conversation_blocks b WHERE b.conversation_id = c.id AND b.blocker_user_id <> :uid
            ) THEN 1 ELSE 0 END) AS blocked_by_other
        FROM conversations c
        JOIN conversation_participants cp ON cp.conversation_id = c.id
        LEFT JOIN listings l ON l.id = c.listing_id
        WHERE cp.user_id = :uid
        ORDER BY COALESCE(
            (SELECT m.created_at FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC, m.id DESC LIMIT 1),
            c.created_at
        ) DESC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([':uid' => $userId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    json_response([
        'success' => true,
        'items' => $rows,
    ]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
