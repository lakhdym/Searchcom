<?php

if (ob_get_level() === 0) {
    ob_start();
}

header('Content-Type: application/json; charset=UTF-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
header("Access-Control-Allow-Origin: $origin");
header('Vary: Origin');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    json_response(['ok' => true]);
}

require_once __DIR__ . '/comment_utils.php';
require_once __DIR__ . '/notification_utils.php';

$body = [];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
}

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : (int)($body['user_id'] ?? 0);
$countOnly = !empty($_GET['count_only']) || (!empty($body['count_only']));
$markRead = true;
if (isset($_GET['mark_read'])) {
    $markRead = filter_var($_GET['mark_read'], FILTER_VALIDATE_BOOLEAN);
} elseif (isset($body['mark_read'])) {
    $markRead = filter_var($body['mark_read'], FILTER_VALIDATE_BOOLEAN);
}
$page = isset($_GET['page']) ? (int)$_GET['page'] : (int)($body['page'] ?? 1);
$perPage = isset($_GET['per_page']) ? (int)$_GET['per_page'] : (int)($body['per_page'] ?? 10);
$page = $page > 0 ? $page : 1;
$perPage = ($perPage > 0 && $perPage <= 50) ? $perPage : 10;
$limit = $perPage;
$offset = ($page - 1) * $perPage;
if ($userId <= 0) {
    json_response(['success' => false, 'message' => 'user_id requis'], 400);
}

try {
    $pdo = get_pdo();
    ensure_comment_schema($pdo);
    ensure_notification_schema($pdo);

    $stmt = $pdo->prepare('SELECT last_seen_at FROM notification_reads WHERE user_id = :uid');
    $stmt->execute([':uid' => $userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    $lastSeen = $row['last_seen_at'] ?? '1970-01-01 00:00:00';

    // compter le non-lu depuis le dernier passage
    $paramsUnread = [':uid' => $userId, ':lastSeen' => $lastSeen];
    $sqlUnread = "
        SELECT COUNT(*) AS cnt FROM (
            SELECT 1
            FROM listing_likes ll
            JOIN listings l ON l.id = ll.listing_id
            JOIN users u ON u.id = ll.user_id
            WHERE l.user_id = :uid AND u.id <> :uid AND ll.created_at > :lastSeen
            UNION ALL
            SELECT 1
            FROM listing_comments c
            JOIN listings l ON l.id = c.listing_id
            JOIN users u ON u.id = c.user_id
            WHERE l.user_id = :uid
              AND u.id <> :uid
              AND c.created_at > :lastSeen
              AND c.deleted_at IS NULL
              AND COALESCE(c.status, 'visible') <> 'hidden'
        ) t
    ";
    $stmt = $pdo->prepare($sqlUnread);
    $stmt->execute($paramsUnread);
    $unreadCount = (int)$stmt->fetchColumn();

    // total notifications (pour has_more)
    $totalSql = "
        SELECT (
            SELECT COUNT(*)
            FROM listing_likes ll
            JOIN listings l ON l.id = ll.listing_id
            JOIN users u ON u.id = ll.user_id
            WHERE l.user_id = :uid AND u.id <> :uid
        ) + (
            SELECT COUNT(*)
            FROM listing_comments c
            JOIN listings l ON l.id = c.listing_id
            JOIN users u ON u.id = c.user_id
            WHERE l.user_id = :uid
              AND u.id <> :uid
              AND c.deleted_at IS NULL
              AND COALESCE(c.status, 'visible') <> 'hidden'
        ) AS total_count
    ";
    $stmt = $pdo->prepare($totalSql);
    $stmt->execute([':uid' => $userId]);
    $totalCount = (int)$stmt->fetchColumn();


    // récupérer l'historique récent (sans supprimer les anciens)
    $params = [':uid' => $userId];
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
            WHERE l.user_id = :uid
              AND u.id <> :uid
              AND c.deleted_at IS NULL
              AND COALESCE(c.status, 'visible') <> 'hidden'
        ) ev
        ORDER BY ev.created_at DESC
        LIMIT :limit OFFSET :offset
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->bindValue(':uid', $userId, PDO::PARAM_INT);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if ($countOnly) {
        json_response(['success' => true, 'count' => $unreadCount]);
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

    // marquer comme lu uniquement lors de la première page, si demandé
    if ($markRead && $page === 1 && !$countOnly) {
        $pdo->prepare('REPLACE INTO notification_reads (user_id, last_seen_at) VALUES (:uid, NOW())')
            ->execute([':uid' => $userId]);
    }

    $hasMore = ($offset + count($items)) < $totalCount;

    json_response([
        'success' => true,
        'items' => $items,
        'unread_count' => $unreadCount,
        'page' => $page,
        'per_page' => $perPage,
        'total' => $totalCount,
        'has_more' => $hasMore,
    ]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
