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
$sinceRaw = $_GET['since'] ?? ($body['since'] ?? null); // ISO datetime optionnel

if ($userId <= 0) {
    json_response(['success' => false, 'message' => 'user_id requis'], 400);
}

try {
    $pdo = get_pdo();

    $params = [':uid' => $userId];
    $sinceClause = '';
    if (!empty($sinceRaw)) {
        $sinceClause = "AND ev.created_at > :since";
        $params[':since'] = $sinceRaw;
    }

    $countSql = "
        SELECT COUNT(*) AS cnt FROM (
            SELECT ll.created_at
            FROM listing_likes ll
            JOIN listings l ON l.id = ll.listing_id
            JOIN users u ON u.id = ll.user_id
            WHERE l.user_id = :uid AND u.id <> :uid
            UNION ALL
            SELECT c.created_at
            FROM listing_comments c
            JOIN listings l ON l.id = c.listing_id
            JOIN users u ON u.id = c.user_id
            WHERE l.user_id = :uid AND u.id <> :uid
        ) ev
        WHERE 1=1
        {$sinceClause}
    ";

    $stmt = $pdo->prepare($countSql);
    $stmt->execute($params);
    $cnt = (int)($stmt->fetchColumn() ?: 0);

    json_response(['success' => true, 'count' => $cnt]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
