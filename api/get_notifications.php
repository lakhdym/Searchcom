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
$countOnly = !empty($_GET['count_only']) || (!empty($body['count_only']));
if ($userId <= 0) {
    json_response(['success' => false, 'message' => 'user_id requis'], 400);
}

try {
    $pdo = get_pdo();

    // table last_seen
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

    $sql = "
        SELECT * FROM (
            SELECT 
                'like' AS type,
                ll.created_at,
                ll.listing_id,
                u.id AS actor_id,
                u.full_name AS actor_name,
                NULL AS content
            FROM listing_likes ll
            JOIN listings l ON l.id = ll.listing_id
            JOIN users u ON u.id = ll.user_id
            WHERE l.user_id = :uid AND u.id <> :uid AND ll.created_at > :lastSeen
            UNION ALL
            SELECT 
                'comment' AS type,
                c.created_at,
                c.listing_id,
                u.id AS actor_id,
                u.full_name AS actor_name,
                c.content AS content
            FROM listing_comments c
            JOIN listings l ON l.id = c.listing_id
            JOIN users u ON u.id = c.user_id
            WHERE l.user_id = :uid AND u.id <> :uid AND c.created_at > :lastSeen
        ) ev
        ORDER BY ev.created_at DESC
        LIMIT 200
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if ($countOnly) {
        json_response(['success' => true, 'count' => count($items)]);
    }

    // Ajouter titres d'annonces
    $listingIds = array_unique(array_filter(array_map(function ($it) {
        return isset($it['listing_id']) ? (int)$it['listing_id'] : 0;
    }, $items)));

    $titles = [];
    if (!empty($listingIds)) {
        $in = implode(',', array_map('intval', $listingIds));
        $tStmt = $pdo->query("SELECT id, title FROM listings WHERE id IN ($in)");
        foreach ($tStmt->fetchAll(PDO::FETCH_ASSOC) as $rowT) {
            $titles[(int)$rowT['id']] = $rowT['title'];
        }
    }

    foreach ($items as &$it) {
        $lid = isset($it['listing_id']) ? (int)$it['listing_id'] : 0;
        $it['listing_title'] = $titles[$lid] ?? '';
    }

    // marquer comme lu maintenant
    $pdo->prepare('REPLACE INTO notification_reads (user_id, last_seen_at) VALUES (:uid, NOW())')
        ->execute([':uid' => $userId]);

    json_response(['success' => true, 'items' => $items]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
