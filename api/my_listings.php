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
$status = $_GET['status'] ?? ($body['status'] ?? null);
$type = $_GET['type'] ?? ($body['type'] ?? null);
$search = $_GET['search'] ?? ($body['search'] ?? null);
$boosted = $_GET['boosted'] ?? ($body['boosted'] ?? null);
$page = max(1, (int)($_GET['page'] ?? ($body['page'] ?? 1)));
$perPage = min(50, max(5, (int)($_GET['per_page'] ?? ($body['per_page'] ?? 20))));

if ($userId <= 0) {
    json_response(['success' => false, 'message' => 'user_id requis'], 400);
}

$where = ['l.user_id = :uid'];
$params = [':uid' => $userId];

$allowedStatus = ['draft','pending_payment','published','hidden','archived'];
if ($status && in_array($status, $allowedStatus, true)) {
    $where[] = 'l.status = :status';
    $params[':status'] = $status;
}
$allowedType = ['lost','found'];
if ($type && in_array($type, $allowedType, true)) {
    $where[] = 'l.type = :type';
    $params[':type'] = $type;
}
if ($boosted !== null) {
    if ($boosted === '1' || $boosted === 1 || $boosted === true || $boosted === 'true') {
        $where[] = 'l.is_boosted = 1';
    } else {
        $where[] = '(l.is_boosted = 0 OR l.is_boosted IS NULL)';
    }
}
if ($search) {
    $where[] = '(l.title LIKE :q OR l.description LIKE :q OR l.city LIKE :q OR l.location_text LIKE :q)';
    $params[':q'] = '%'.$search.'%';
}

$whereSql = implode(' AND ', $where);
$offset = ($page - 1) * $perPage;

try {
    $pdo = get_pdo();
    ensure_comment_schema($pdo);

    // Total
    $countStmt = $pdo->prepare("SELECT COUNT(*) FROM listings l WHERE $whereSql");
    $countStmt->execute($params);
    $total = (int)$countStmt->fetchColumn();

    // Items
    $sql = "
      SELECT
        l.id, l.user_id, l.type, l.status, l.title, l.description, l.category_id,
        l.city, l.location_text, l.event_date, l.contact_chat, l.contact_whatsapp, l.contact_call,
        l.is_boosted, l.published_at, l.created_at, l.updated_at,
        NULL AS category_name,
        (SELECT url FROM listing_photos p WHERE p.listing_id = l.id ORDER BY p.position ASC, p.id ASC LIMIT 1) AS cover_photo_url,
        (SELECT COUNT(*) FROM listing_likes ll WHERE ll.listing_id = l.id) AS likes_count,
        (
          SELECT COUNT(*)
          FROM listing_comments lc
          WHERE lc.listing_id = l.id
            AND lc.deleted_at IS NULL
            AND COALESCE(lc.status, 'visible') = 'visible'
        ) AS comments_count,
        (SELECT COUNT(*) FROM listing_likes ll2 WHERE ll2.listing_id = l.id AND ll2.user_id = :uid) AS liked_by_me,
        (SELECT status FROM payments pay WHERE pay.listing_id = l.id AND pay.purpose = 'publish' ORDER BY pay.id DESC LIMIT 1) AS payment_status
      FROM listings l
      WHERE $whereSql
      ORDER BY l.created_at DESC
      LIMIT :offset, :perPage
    ";
    $stmt = $pdo->prepare($sql);
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->bindValue(':perPage', $perPage, PDO::PARAM_INT);
    $stmt->execute();
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // RÃ©cupÃ©rer les photos pour ces listings
    $ids = array_column($items, 'id');
    $photosByListing = [];
    if (!empty($ids)) {
        $in = implode(',', array_fill(0, count($ids), '?'));
        $pStmt = $pdo->prepare("SELECT id, listing_id, url FROM listing_photos WHERE listing_id IN ($in) ORDER BY position ASC, id ASC");
        foreach ($ids as $k => $id) {
            $pStmt->bindValue($k + 1, (int)$id, PDO::PARAM_INT);
        }
        $pStmt->execute();
        while ($row = $pStmt->fetch(PDO::FETCH_ASSOC)) {
            $lid = (int)$row['listing_id'];
            $photosByListing[$lid][] = [
                'id' => (int)$row['id'],
                'url' => $row['url'],
            ];
        }
    }

    // Injecter les photos dans les items
    foreach ($items as &$it) {
        $lid = (int)$it['id'];
        $it['photos'] = $photosByListing[$lid] ?? [];
    }
    unset($it);

    json_response([
        'success' => true,
        'page' => $page,
        'per_page' => $perPage,
        'total' => $total,
        'items' => $items,
    ]);
} catch (Throwable $e) {
    json_response(['success' => false, 'message' => 'Erreur serveur : ' . $e->getMessage()], 500);
}
