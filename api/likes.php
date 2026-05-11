<?php
// api/likes.php
ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('error_log', __DIR__ . '/api_error.log');
error_reporting(E_ALL);

set_exception_handler(function ($e) {
    http_response_code(500);
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode([
        "error" => "Server error",
        "details" => $e->getMessage(),
    ]);
    error_log((string) $e);
    exit;
});

set_error_handler(function ($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

header('Content-Type: application/json; charset=UTF-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Pragma: no-cache');
header('Expires: 0');

$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$allowed = [
    'https://italents.ma',
    'https://www.italents.ma',
];

// allow localhost:anyport for Flutter web dev
$isLocalhost = preg_match('#^http://localhost:\d+$#', $origin) || preg_match('#^http://127\.0\.0\.1:\d+$#', $origin);

if ($isLocalhost || in_array($origin, $allowed, true)) {
    header("Access-Control-Allow-Origin: $origin");
    header("Vary: Origin");
}

header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    echo json_encode(["ok" => true]);
    exit;
}

require_once __DIR__ . '/config.php';

$auth = $_SERVER['HTTP_AUTHORIZATION'] ?? ($_SERVER['Authorization'] ?? '');
$payload = null;
if ($auth && preg_match('/Bearer\\s+(.*)$/i', $auth, $matches)) {
    $token = $matches[1];
    $payload = verify_jwt($token);
    if ($payload === null && $_SERVER['REQUEST_METHOD'] === 'POST') {
        json_response(['error' => 'Token invalide ou expiré'], 401);
    }
}

$method = $_SERVER['REQUEST_METHOD'];
$pdo = get_pdo();

function table_exists_like(PDO $pdo, string $tableName): bool
{
    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = :table
            LIMIT 1
        ");
        $stmt->execute([':table' => $tableName]);
        return (bool) $stmt->fetchColumn();
    } catch (Throwable $e) {
        return false;
    }
}

if ($method === 'GET') {
    $listingId = isset($_GET['listing_id']) ? (int) $_GET['listing_id'] : 0;
    if ($listingId <= 0) {
        json_response(['error' => 'listing_id requis'], 400);
    }

    if (!table_exists_like($pdo, 'listing_likes')) {
        json_response([]);
    }

    $hasUsersTable = table_exists_like($pdo, 'users');

    $sql = "
        SELECT ll.user_id, ll.listing_id, ll.created_at" . ($hasUsersTable ? ", u.full_name" : "") . "
        FROM listing_likes ll
        " . ($hasUsersTable ? "LEFT JOIN users u ON ll.user_id = u.id" : "") . "
        WHERE ll.listing_id = :listing_id
        ORDER BY ll.created_at DESC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([':listing_id' => $listingId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $likes = array_map(function ($row) {
        $userId = isset($row['user_id']) ? (int) $row['user_id'] : null;
        $fullName = trim((string) ($row['full_name'] ?? ''));
        if ($fullName === '' && $userId !== null) {
            $fullName = 'Utilisateur #' . $userId;
        }

        return [
            'user_id' => $userId,
            'listing_id' => isset($row['listing_id']) ? (int) $row['listing_id'] : null,
            'full_name' => $fullName,
            'created_at' => $row['created_at'] ?? null,
        ];
    }, $rows);

    json_response($likes);
}

if ($method === 'POST') {
    if ($payload === null) {
        json_response(['error' => 'Token manquant'], 401);
    }

    $body = json_decode(file_get_contents('php://input'), true) ?? [];
    $listingId = isset($body['listing_id']) ? (int) $body['listing_id'] : 0;
    if ($listingId <= 0) {
        json_response(['error' => 'listing_id requis'], 400);
    }

    if (!table_exists_like($pdo, 'listing_likes')) {
        json_response(['error' => 'Table listing_likes introuvable'], 404);
    }

    $userId = isset($payload['sub']) ? (int) $payload['sub'] : 0;
    if ($userId <= 0) {
        json_response(['error' => 'Utilisateur invalide dans le token'], 401);
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM listing_likes
            WHERE listing_id = :listing_id AND user_id = :user_id
            LIMIT 1
        ");
        $stmt->execute([
            ':listing_id' => $listingId,
            ':user_id' => $userId,
        ]);

        $exists = (bool) $stmt->fetchColumn();
        $liked = false;

        if ($exists) {
            $del = $pdo->prepare("
                DELETE FROM listing_likes
                WHERE listing_id = :listing_id AND user_id = :user_id
            ");
            $del->execute([
                ':listing_id' => $listingId,
                ':user_id' => $userId,
            ]);
            $liked = false;
        } else {
            $ins = $pdo->prepare("
                INSERT INTO listing_likes (listing_id, user_id, created_at)
                VALUES (:listing_id, :user_id, :created_at)
            ");
            $ins->execute([
                ':listing_id' => $listingId,
                ':user_id' => $userId,
                ':created_at' => date('Y-m-d H:i:s'),
            ]);
            $liked = true;
        }

        $countStmt = $pdo->prepare("
            SELECT COUNT(*) FROM listing_likes WHERE listing_id = :listing_id
        ");
        $countStmt->execute([':listing_id' => $listingId]);
        $likesCount = (int) $countStmt->fetchColumn();

        $pdo->commit();

        json_response([
            'liked' => $liked,
            'likes_count' => $likesCount,
        ], 200);
    } catch (Throwable $e) {
        $pdo->rollBack();
        json_response([
            'error' => 'Impossible de mettre à jour le like',
            'details' => $e->getMessage(),
        ], 500);
    }
}

json_response(['error' => 'Method not allowed'], 405);
