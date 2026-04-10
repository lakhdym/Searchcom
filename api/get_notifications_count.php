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
require_once __DIR__ . '/comment_utils.php';

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
    ensure_comment_schema($pdo);

    // table pour mémoriser la dernière consultation
    $pdo->exec("CREATE TABLE IF NOT EXISTS notification_reads (
        user_id BIGINT PRIMARY KEY,
        last_seen_at DATETIME NOT NULL DEFAULT '1970-01-01 00:00:00',
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    $stmt = $pdo->prepare('SELECT last_seen_at FROM notification_reads WHERE user_id = :uid');
    $stmt->execute([':uid' => $userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $lastSeen = $row['last_seen_at'] ?? '1970-01-01 00:00:00';

    $params = [':uid' => $userId, ':lastSeen' => $lastSeen];

    $countSql = "
        SELECT COUNT(*) AS cnt FROM (
            SELECT ll.created_at
            FROM listing_likes ll
            JOIN listings l ON l.id = ll.listing_id
            JOIN users u ON u.id = ll.user_id
            WHERE l.user_id = :uid AND u.id <> :uid AND ll.created_at > :lastSeen
            UNION ALL
            SELECT c.created_at
            FROM listing_comments c
            JOIN listings l ON l.id = c.listing_id
            JOIN users u ON u.id = c.user_id
            WHERE l.user_id = :uid
              AND u.id <> :uid
              AND c.created_at > :lastSeen
              AND c.deleted_at IS NULL
              AND COALESCE(c.status, 'visible') <> 'hidden'
        ) ev
    ";

    $stmt = $pdo->prepare($countSql);
    $stmt->execute($params);
    $cnt = (int)($stmt->fetchColumn() ?: 0);

    json_response(['success' => true, 'count' => $cnt]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
