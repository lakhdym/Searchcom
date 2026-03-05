<?php
// api/comments.php
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
if (preg_match('/Bearer\\s+(.*)$/i', $auth, $matches)) {
    $token = $matches[1];
    $payload = verify_jwt($token);
    if ($payload === null) {
        json_response(['error' => 'Token invalide ou expirÃ©'], 401);
    }
}

$method = $_SERVER['REQUEST_METHOD'];
$pdo = get_pdo();

function table_exists_comments(PDO $pdo): bool
{
    try {
        $stmt = $pdo->prepare("
            SELECT 1
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'listing_comments'
            LIMIT 1
        ");
        $stmt->execute();
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

    if (!table_exists_comments($pdo)) {
        json_response([]); // table absente => pas de commentaires
    }

    $stmt = $pdo->prepare("
            SELECT l.id as id , listing_id, full_name ,  user_id, content, status, l.created_at 
        FROM listing_comments l INNER JOIN users u ON l.user_id = u.id
        WHERE listing_id = :listing_id
        ORDER BY l.created_at DESC;
    ");
    $stmt->execute([':listing_id' => $listingId]);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $comments = array_map(function ($row) {
        return [
            'id' => (int) ($row['id'] ?? 0),
            'listing_id' => (int) ($row['listing_id'] ?? 0),
            // 'user_id' => isset($row['user_id']) ? (int) $row['user_id'] : null,
            'user_id' => isset($row['user_id']) ? (int) $row['user_id'] : null,
            'full_name' => (string) ($row['full_name'] ?? ''),
            'content' => (string) ($row['content'] ?? ''),
            'status' => $row['status'] ?? null,
            'created_at' => $row['created_at'] ?? null,
        ];
    }, $rows);

    json_response($comments);
}

if ($method === 'POST') {
    if ($payload === null) {
        json_response(['error' => 'Token manquant'], 401);
    }

    $body = json_decode(file_get_contents('php://input'), true) ?? [];
    $listingId = isset($body['listing_id']) ? (int) $body['listing_id'] : 0;
    $content = trim($body['content'] ?? '');

    if ($listingId <= 0 || $content === '') {
        json_response(['error' => 'listing_id et content requis'], 400);
    }

    if (!table_exists_comments($pdo)) {
        json_response(['error' => 'Table listing_comments introuvable'], 404);
    }

    $userId = isset($payload['sub']) ? (int) $payload['sub'] : 0;
    $status = 'approved';
    $now = date('Y-m-d H:i:s');

    $stmt = $pdo->prepare("
        INSERT INTO listing_comments (listing_id, user_id, content, status, created_at)
        VALUES (:listing_id, :user_id, :content, :status, :created_at)
    ");
    $stmt->execute([
        ':listing_id' => $listingId,
        ':user_id' => $userId,
        ':content' => $content,
        ':status' => $status,
        ':created_at' => $now,
    ]);

    $id = (int) $pdo->lastInsertId();

    $stmt = $pdo->prepare("
        SELECT id, listing_id, user_id, content, status, created_at
        FROM listing_comments
        WHERE id = :id
    ");
    $stmt->execute([':id' => $id]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row) {
        json_response(['error' => 'Commentaire enregistrÃ© mais introuvable'], 201);
    }

    $comment = [
        'id' => (int) ($row['id'] ?? $id),
        'listing_id' => (int) ($row['listing_id'] ?? $listingId),
        'user_id' => isset($row['user_id']) ? (int) $row['user_id'] : null,
        'content' => (string) ($row['content'] ?? $content),
        'status' => $row['status'] ?? $status,
        'created_at' => $row['created_at'] ?? $now,
    ];

    json_response($comment, 201);
}

json_response(['error' => 'Method not allowed'], 405);
