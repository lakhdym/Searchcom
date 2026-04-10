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

$listingId = isset($_GET['listing_id']) ? (int)$_GET['listing_id'] : (int)($body['listing_id'] ?? 0);
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : (int)($body['user_id'] ?? 0); // optionnel pour liked_by_me

if ($listingId <= 0) {
    json_response(['success' => false, 'message' => 'listing_id requis'], 400);
}

try {
    $pdo = get_pdo();
    ensure_comment_schema($pdo);

    $stmt = $pdo->prepare("
        SELECT l.*,
               c.name_fr AS category_name,
               (SELECT url FROM listing_photos p WHERE p.listing_id = l.id ORDER BY p.position, p.id LIMIT 1) AS cover_photo_url,
               (SELECT COUNT(*) FROM listing_likes ll WHERE ll.listing_id = l.id) AS likes_count,
               (
                 SELECT COUNT(*)
                 FROM listing_comments lc
                 WHERE lc.listing_id = l.id
                   AND lc.deleted_at IS NULL
                   AND COALESCE(lc.status, 'visible') <> 'hidden'
               ) AS comments_count,
               CASE WHEN :uid > 0 THEN
                 (SELECT 1 FROM listing_likes ll WHERE ll.listing_id = l.id AND ll.user_id = :uid LIMIT 1)
               ELSE 0 END AS liked_by_me
        FROM listings l
        LEFT JOIN categories c ON c.id = l.category_id
        WHERE l.id = :lid
        LIMIT 1
    ");
    $stmt->execute([':lid' => $listingId, ':uid' => $userId]);
    $listing = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$listing) {
        json_response(['success' => false, 'message' => 'Annonce introuvable'], 404);
    }

    $photosStmt = $pdo->prepare("SELECT id, url, position FROM listing_photos WHERE listing_id = :lid ORDER BY position, id");
    $photosStmt->execute([':lid' => $listingId]);
    $listing['photos'] = $photosStmt->fetchAll(PDO::FETCH_ASSOC);

    json_response(['success' => true, 'listing' => $listing]);
} catch (Exception $e) {
    json_response(['success' => false, 'message' => $e->getMessage()], 500);
}
