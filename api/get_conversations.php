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

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : (int)($body['user_id'] ?? 0);
if ($userId <= 0) {
    json_response(['success' => false, 'message' => 'user_id requis'], 400);
}

try {
    $pdo = get_pdo();

    $sql = "
        SELECT
            c.id,
            c.listing_id,
            l.title AS listing_title,
            -- autre participant
            (SELECT u2.id FROM conversation_participants cp2 JOIN users u2 ON u2.id = cp2.user_id
             WHERE cp2.conversation_id = c.id AND cp2.user_id <> :uid LIMIT 1) AS other_user_id,
            (SELECT u2.full_name FROM conversation_participants cp2 JOIN users u2 ON u2.id = cp2.user_id
             WHERE cp2.conversation_id = c.id AND cp2.user_id <> :uid LIMIT 1) AS other_user_name,
            -- dernier message
            (SELECT m.content FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) AS last_message,
            (SELECT m.created_at FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) AS last_message_at,
            -- non lus
            COALESCE((
                SELECT COUNT(*) FROM messages m
                JOIN conversation_participants cp ON cp.conversation_id = m.conversation_id AND cp.user_id = :uid
                WHERE m.conversation_id = c.id
                  AND m.sender_user_id <> :uid
                  AND (cp.last_read_at IS NULL OR m.created_at > cp.last_read_at)
            ), 0) AS unread_count
        FROM conversations c
        JOIN conversation_participants cp ON cp.conversation_id = c.id
        LEFT JOIN listings l ON l.id = c.listing_id
        WHERE cp.user_id = :uid
        ORDER BY COALESCE(
            (SELECT m.created_at FROM messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1),
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
