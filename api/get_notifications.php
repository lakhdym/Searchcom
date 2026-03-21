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
$countOnly = !empty($_GET['count_only']) || (!empty($body['count_only']));

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

    // Construction d'un flux unifié likes + commentaires
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
            WHERE l.user_id = :uid AND u.id <> :uid
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
            WHERE l.user_id = :uid AND u.id <> :uid
        ) ev
        WHERE 1=1
        {$sinceClause}
        ORDER BY ev.created_at DESC
        LIMIT 200
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if ($countOnly) {
        $countSql = "
            SELECT COUNT(*) AS cnt FROM (
                SELECT 
                    ll.created_at
                FROM listing_likes ll
                JOIN listings l ON l.id = ll.listing_id
                JOIN users u ON u.id = ll.user_id
                WHERE l.user_id = :uid AND u.id <> :uid
                UNION ALL
                SELECT 
                    c.created_at
                FROM listing_comments c
                JOIN listings l ON l.id = c.listing_id
                JOIN users u ON u.id = c.user_id
                WHERE l.user_id = :uid AND u.id <> :uid
            ) ev
            WHERE 1=1
            {$sinceClause}
        ";
        $cStmt = $pdo->prepare($countSql);
        $cStmt->execute($params);
        $cnt = (int)($cStmt->fetchColumn() ?: 0);
        json_response(['success' => true, 'count' => $cnt]);
    }

    // Ajouter titres d'annonces
    $listingIds = array_unique(array_filter(array_map(function ($it) {
        return isset($it['listing_id']) ? (int)$it['listing_id'] : 0;
    }, $items)));

    $titles = [];
    if (!empty($listingIds)) {
        $in = implode(',', array_map('intval', $listingIds));
        $tStmt = $pdo->query("SELECT id, title FROM listings WHERE id IN ($in)");
        foreach ($tStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $titles[(int)$row['id']] = $row['title'];
        }
    }

    foreach ($items as &$it) {
        $lid = isset($it['listing_id']) ? (int)$it['listing_id'] : 0;
        $it['listing_title'] = $titles[$lid] ?? '';
    }

    json_response(['success' => true, 'items' => $items]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
